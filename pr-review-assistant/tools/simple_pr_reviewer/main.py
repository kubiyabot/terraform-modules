#!/usr/bin/env python3
import os
import json
import re
from typing import Dict, Any, List
from kubiya_sdk.tools import function_tool
from github import Github
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

@function_tool(
    description="Simple PR reviewer that analyzes and comments on GitHub PRs with Slack notifications",
    requirements=["PyGithub==2.1.1", "slack-sdk==3.23.0"],
    env=["GITHUB_TOKEN", "SLACK_TOKEN"],
    secrets=["GITHUB_TOKEN", "SLACK_TOKEN"]
)
def review_and_notify_pr(
    pr_url: str,
    slack_channel: str = None
) -> Dict[str, Any]:
    """
    Review a GitHub PR, comment with recommendations, and notify via Slack.
    
    Args:
        pr_url: GitHub pull request URL
        slack_channel: Slack channel for notifications (optional, uses default if not provided)
    
    Returns:
        Dictionary with review results and notification status
    """
    # Initialize clients
    github_token = os.environ.get('GITHUB_TOKEN')
    slack_token = os.environ.get('SLACK_TOKEN')
    g = Github(github_token)
    slack = WebClient(token=slack_token)
    
    result = {
        "pr_url": pr_url,
        "status": "processing",
        "steps": {}
    }
    
    try:
        # Step 1: Get PR from GitHub
        pr_data = get_pr_details(g, pr_url)
        result["steps"]["fetch_pr"] = "✅ Fetched PR details"
        
        # Step 2: Get repo owner and reviewers
        reviewers = get_reviewers(pr_data)
        result["steps"]["identify_reviewers"] = f"✅ Identified reviewers: {', '.join(reviewers['github_users'])}"
        
        # Step 3: Analyze the PR
        analysis = analyze_pr(pr_data)
        result["steps"]["analyze"] = "✅ Completed PR analysis"
        
        # Step 4: Comment on PR with recommendation
        comment_result = post_pr_comment(pr_data, analysis, reviewers)
        result["steps"]["comment"] = "✅ Posted PR comment with recommendation"
        
        # Step 5: Send Slack notification
        slack_result = send_slack_notification(
            slack, 
            pr_data, 
            analysis, 
            reviewers, 
            slack_channel
        )
        result["steps"]["slack"] = "✅ Sent Slack notification"
        
        result["status"] = "completed"
        result["recommendation"] = analysis["recommendation"]
        result["risk_score"] = analysis["risk_score"]
        
    except Exception as e:
        result["status"] = "error"
        result["error"] = str(e)
    
    return result

def get_pr_details(github_client: Github, pr_url: str) -> Dict[str, Any]:
    """Fetch PR details from GitHub"""
    # Parse PR URL
    match = re.match(r'https://github.com/([^/]+)/([^/]+)/pull/(\d+)', pr_url)
    if not match:
        raise ValueError("Invalid PR URL format")
    
    owner, repo_name, pr_number = match.groups()
    
    # Get repository and PR
    repo = github_client.get_repo(f"{owner}/{repo_name}")
    pr = repo.get_pull(int(pr_number))
    
    # Get files changed
    files = list(pr.get_files())
    
    return {
        "repo": repo,
        "pr": pr,
        "owner": owner,
        "repo_name": repo_name,
        "pr_number": pr_number,
        "author": pr.user.login,
        "title": pr.title,
        "description": pr.body or "",
        "files": files,
        "additions": pr.additions,
        "deletions": pr.deletions,
        "changed_files": pr.changed_files,
        "base_branch": pr.base.ref,
        "head_branch": pr.head.ref
    }

def get_reviewers(pr_data: Dict[str, Any]) -> Dict[str, List[str]]:
    """Identify repo owner and assigned reviewers"""
    pr = pr_data["pr"]
    repo = pr_data["repo"]
    
    reviewers = {
        "github_users": [],
        "slack_users": []  # Would need mapping in production
    }
    
    # Add repo owner
    reviewers["github_users"].append(repo.owner.login)
    
    # Add PR author
    reviewers["github_users"].append(pr.user.login)
    
    # Add requested reviewers
    for reviewer in pr.requested_reviewers:
        reviewers["github_users"].append(reviewer.login)
    
    # Add assignees
    for assignee in pr.assignees:
        reviewers["github_users"].append(assignee.login)
    
    # Remove duplicates
    reviewers["github_users"] = list(set(reviewers["github_users"]))
    
    # Map to Slack users (simplified - in production would use a mapping)
    reviewers["slack_users"] = [f"@{user}" for user in reviewers["github_users"]]
    
    return reviewers

def analyze_pr(pr_data: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze PR for security, quality, and risk"""
    analysis = {
        "issues": [],
        "warnings": [],
        "suggestions": [],
        "risk_score": 0,
        "recommendation": "APPROVE",
        "reasoning": []
    }
    
    # Check file changes
    for file in pr_data["files"]:
        if file.status == "removed":
            continue
        
        # Security checks
        if file.patch:
            # Check for hardcoded secrets
            if re.search(r'(password|api_key|secret|token)\s*=\s*["\'][^"\']+["\']', 
                        file.patch, re.IGNORECASE):
                analysis["issues"].append(f"⚠️ Potential hardcoded credentials in {file.filename}")
                analysis["risk_score"] += 30
            
            # Check for SQL injection
            if re.search(r'f["\'].*SELECT.*{.*}.*FROM', file.patch, re.IGNORECASE):
                analysis["issues"].append(f"⚠️ Potential SQL injection in {file.filename}")
                analysis["risk_score"] += 25
            
            # Check for eval/exec
            if 'eval(' in file.patch or 'exec(' in file.patch:
                analysis["issues"].append(f"⚠️ Dangerous eval/exec usage in {file.filename}")
                analysis["risk_score"] += 20
    
    # Size checks
    if pr_data["changed_files"] > 50:
        analysis["warnings"].append(f"Large PR: {pr_data['changed_files']} files changed")
        analysis["risk_score"] += 10
    
    if pr_data["additions"] + pr_data["deletions"] > 1000:
        analysis["warnings"].append(f"Large changeset: {pr_data['additions'] + pr_data['deletions']} lines")
        analysis["risk_score"] += 10
    
    # Determine recommendation
    if analysis["risk_score"] >= 50:
        analysis["recommendation"] = "REQUEST_CHANGES"
        analysis["reasoning"].append("High risk score due to security concerns")
    elif analysis["risk_score"] >= 25:
        analysis["recommendation"] = "COMMENT"
        analysis["reasoning"].append("Medium risk - careful review recommended")
    else:
        analysis["recommendation"] = "APPROVE"
        analysis["reasoning"].append("Low risk changes")
    
    # Add general reasoning
    if not analysis["issues"] and not analysis["warnings"]:
        analysis["reasoning"].append("No security or quality issues detected")
    
    return analysis

def post_pr_comment(pr_data: Dict[str, Any], analysis: Dict[str, Any], reviewers: Dict[str, List[str]]) -> bool:
    """Post analysis comment on the PR"""
    pr = pr_data["pr"]
    
    # Build comment
    comment = f"## 🤖 Automated PR Review\n\n"
    
    # Recommendation
    if analysis["recommendation"] == "APPROVE":
        comment += "### ✅ Recommendation: **APPROVE**\n\n"
    elif analysis["recommendation"] == "REQUEST_CHANGES":
        comment += "### ❌ Recommendation: **REQUEST CHANGES**\n\n"
    else:
        comment += "### 💬 Recommendation: **NEEDS DISCUSSION**\n\n"
    
    # Risk Score
    comment += f"**Risk Score:** {analysis['risk_score']}/100\n\n"
    
    # Issues
    if analysis["issues"]:
        comment += "### 🔴 Issues Found\n"
        for issue in analysis["issues"]:
            comment += f"- {issue}\n"
        comment += "\n"
    
    # Warnings
    if analysis["warnings"]:
        comment += "### 🟡 Warnings\n"
        for warning in analysis["warnings"]:
            comment += f"- {warning}\n"
        comment += "\n"
    
    # Reasoning
    comment += "### 📋 Reasoning\n"
    for reason in analysis["reasoning"]:
        comment += f"- {reason}\n"
    comment += "\n"
    
    # Tag reviewers
    comment += "### 👥 Reviewers\n"
    comment += "cc: " + " ".join([f"@{user}" for user in reviewers["github_users"]])
    comment += "\n\n---\n"
    comment += "*This review was automatically generated by Kubiya PR Assistant*"
    
    # Post comment
    pr.create_issue_comment(comment)
    
    # Also create a review if needed
    if analysis["recommendation"] in ["APPROVE", "REQUEST_CHANGES"]:
        event = "APPROVE" if analysis["recommendation"] == "APPROVE" else "REQUEST_CHANGES"
        pr.create_review(body=comment, event=event)
    
    return True

def send_slack_notification(
    slack_client: WebClient,
    pr_data: Dict[str, Any],
    analysis: Dict[str, Any],
    reviewers: Dict[str, List[str]],
    channel: str = None
) -> bool:
    """Send detailed Slack notification"""
    
    channel = channel or os.environ.get('SLACK_CHANNEL', '#pr-reviews')
    
    # Build Slack message blocks
    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"🔍 PR Review: {pr_data['title']}"
            }
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Repository:*\n{pr_data['repo_name']}"},
                {"type": "mrkdwn", "text": f"*Author:*\n{pr_data['author']}"},
                {"type": "mrkdwn", "text": f"*PR Number:*\n#{pr_data['pr_number']}"},
                {"type": "mrkdwn", "text": f"*Risk Score:*\n{analysis['risk_score']}/100"}
            ]
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Recommendation:* {analysis['recommendation']}"
            }
        }
    ]
    
    # Add issues if any
    if analysis["issues"]:
        issues_text = "*Issues Found:*\n"
        for issue in analysis["issues"]:
            issues_text += f"• {issue}\n"
        blocks.append({
            "type": "section",
            "text": {"type": "mrkdwn", "text": issues_text}
        })
    
    # Add warnings if any
    if analysis["warnings"]:
        warnings_text = "*Warnings:*\n"
        for warning in analysis["warnings"]:
            warnings_text += f"• {warning}\n"
        blocks.append({
            "type": "section",
            "text": {"type": "mrkdwn", "text": warnings_text}
        })
    
    # Add PR link
    blocks.append({
        "type": "actions",
        "elements": [
            {
                "type": "button",
                "text": {"type": "plain_text", "text": "View PR"},
                "url": pr_data["pr"].html_url
            }
        ]
    })
    
    # Add mentions
    mentions = " ".join(reviewers["slack_users"])
    blocks.append({
        "type": "context",
        "elements": [
            {"type": "mrkdwn", "text": f"Reviewers: {mentions}"}
        ]
    })
    
    try:
        response = slack_client.chat_postMessage(
            channel=channel,
            blocks=blocks,
            text=f"PR Review for {pr_data['title']}"  # Fallback text
        )
        return True
    except SlackApiError as e:
        print(f"Slack error: {e.response['error']}")
        return False