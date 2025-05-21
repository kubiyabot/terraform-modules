#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.error
import urllib.parse
import base64
import ssl
import re

# Function to convert HTML to plain text with better formatting preservation
def html_to_text(html_content):
    # Process the content in stages to better preserve structure
    
    # 1. Handle special Confluence macros and elements
    html_content = re.sub(r'<ac:link[^>]*>.*?</ac:link>', '', html_content)  # Remove Confluence links
    
    # 2. Handle headers
    html_content = re.sub(r'<h1[^>]*>(.*?)</h1>', r'\n\n# \1\n\n', html_content)
    html_content = re.sub(r'<h2[^>]*>(.*?)</h2>', r'\n\n## \1\n\n', html_content)
    html_content = re.sub(r'<h3[^>]*>(.*?)</h3>', r'\n\n### \1\n\n', html_content)
    html_content = re.sub(r'<h4[^>]*>(.*?)</h4>', r'\n\n#### \1\n\n', html_content)
    html_content = re.sub(r'<h5[^>]*>(.*?)</h5>', r'\n\n##### \1\n\n', html_content)
    html_content = re.sub(r'<h6[^>]*>(.*?)</h6>', r'\n\n###### \1\n\n', html_content)
    
    # 3. Handle lists - preserve nesting structure
    # Convert unordered lists
    html_content = re.sub(r'<ul[^>]*>', r'\n', html_content)
    html_content = re.sub(r'</ul>', r'\n', html_content)
    
    # Convert list items with proper indentation
    html_content = re.sub(r'<li[^>]*>(.*?)</li>', r'- \1\n', html_content)
    
    # Convert ordered lists
    html_content = re.sub(r'<ol[^>]*>', r'\n', html_content)
    html_content = re.sub(r'</ol>', r'\n', html_content)
    
    # 4. Handle paragraphs and line breaks
    html_content = re.sub(r'<p[^>]*>(.*?)</p>', r'\n\n\1\n\n', html_content)
    html_content = re.sub(r'<br[^>]*>', r'\n', html_content)
    html_content = re.sub(r'<div[^>]*>(.*?)</div>', r'\n\1\n', html_content)
    
    # 5. Handle text formatting
    html_content = re.sub(r'<strong[^>]*>(.*?)</strong>', r'**\1**', html_content)
    html_content = re.sub(r'<b[^>]*>(.*?)</b>', r'**\1**', html_content)
    html_content = re.sub(r'<em[^>]*>(.*?)</em>', r'*\1*', html_content)
    html_content = re.sub(r'<i[^>]*>(.*?)</i>', r'*\1*', html_content)
    html_content = re.sub(r'<u[^>]*>(.*?)</u>', r'_\1_', html_content)
    html_content = re.sub(r'<code[^>]*>(.*?)</code>', r'`\1`', html_content)
    html_content = re.sub(r'<pre[^>]*>(.*?)</pre>', r'```\n\1\n```', html_content, flags=re.DOTALL)
    
    # 6. Handle links
    html_content = re.sub(r'<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>', r'[\2](\1)', html_content)
    
    # 7. Handle tables (simplified conversion)
    html_content = re.sub(r'<table[^>]*>.*?</table>', r'\n[Table content omitted]\n', html_content, flags=re.DOTALL)
    
    # 8. Remove remaining HTML tags
    html_content = re.sub(r'<[^>]+>', ' ', html_content)
    
    # 9. Replace HTML entities
    entities = {
        '&nbsp;': ' ',
        '&lt;': '<',
        '&gt;': '>',
        '&amp;': '&',
        '&quot;': '"',
        '&apos;': "'",
        '&ldquo;': '"',
        '&rdquo;': '"',
        '&lsquo;': "'",
        '&rsquo;': "'",
        '&mdash;': '—',
        '&ndash;': '–',
        '&rarr;': '→',
        '&larr;': '←',
        '&uarr;': '↑',
        '&darr;': '↓',
        '&hellip;': '...',
    }
    
    for entity, replacement in entities.items():
        html_content = html_content.replace(entity, replacement)
    
    # 10. Clean up excessive whitespace while preserving paragraph breaks
    # Replace multiple newlines with just two (to create paragraph breaks)
    html_content = re.sub(r'\n{3,}', '\n\n', html_content)
    
    # Replace multiple spaces with a single space
    html_content = re.sub(r' +', ' ', html_content)
    
    # Trim leading/trailing whitespace
    html_content = html_content.strip()
    
    return html_content

# Simple function to make HTTP requests using only standard library
def make_request(url, username, api_token):
    try:
        # Create authorization header
        auth = f"{username}:{api_token}"
        auth_bytes = auth.encode('ascii')
        base64_bytes = base64.b64encode(auth_bytes)
        auth_header = f"Basic {base64_bytes.decode('ascii')}"
        
        # Create request with headers
        req = urllib.request.Request(url)
        req.add_header('Authorization', auth_header)
        req.add_header('Accept', 'application/json')
        
        # Make request with SSL context
        context = ssl.create_default_context()
        response = urllib.request.urlopen(req, context=context, timeout=30)
        
        # Read and decode response
        data = response.read().decode('utf-8')
        return json.loads(data)
    except urllib.error.HTTPError as e:
        return {"error": f"HTTP Error: {e.code} - {e.reason}"}
    except urllib.error.URLError as e:
        return {"error": f"URL Error: {e.reason}"}
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

def main():
    # Read input from stdin
    try:
        input_data = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        print(json.dumps({"error": "Failed to parse input JSON"}))
        sys.exit(1)
    
    # Extract parameters
    confluence_url = input_data.get("CONFLUENCE_URL", "").rstrip('/')
    username = input_data.get("CONFLUENCE_USERNAME", "")
    api_token = input_data.get("CONFLUENCE_API_TOKEN", "")
    space_key = input_data.get("space_key", "")
    include_blogs = input_data.get("include_blogs", "true").lower() == "true"
    
    # Check for required parameters
    if not confluence_url or not username or not api_token or not space_key:
        print(json.dumps({"error": "Missing required parameters"}))
        sys.exit(1)
    
    # Test connection
    test_url = f"{confluence_url}/rest/api/space?limit=1"
    test_result = make_request(test_url, username, api_token)
    
    if "error" in test_result:
        print(json.dumps({"error": f"Confluence connection failed: {test_result['error']}"}))
        sys.exit(1)
    
    # Get space content
    content_url = f"{confluence_url}/rest/api/space/{space_key}/content?limit=100"
    content_result = make_request(content_url, username, api_token)
    
    if "error" in content_result:
        print(json.dumps({"error": f"Failed to retrieve content: {content_result['error']}"}))
        sys.exit(1)
    
    # Process pages and blogs
    items = []
    
    # Process pages
    if "page" in content_result and "results" in content_result["page"]:
        for page in content_result["page"]["results"]:
            page_id = page.get("id")
            if page_id:
                # Get page content
                page_url = f"{confluence_url}/rest/api/content/{page_id}?expand=body.storage,metadata.labels"
                page_data = make_request(page_url, username, api_token)
                
                if "error" not in page_data:
                    # Extract content and labels
                    content = page_data.get("body", {}).get("storage", {}).get("value", "")
                    clean_content = html_to_text(content)
                    
                    # Skip empty pages
                    if not clean_content or clean_content.strip() == "":
                        continue
                    
                    # Extract labels
                    labels = []
                    if "metadata" in page_data and "labels" in page_data["metadata"] and "results" in page_data["metadata"]["labels"]:
                        for label in page_data["metadata"]["labels"]["results"]:
                            if "name" in label:
                                labels.append(label["name"])
                    
                    # Add to items
                    items.append({
                        "id": page_data.get("id"),
                        "title": page_data.get("title", "Untitled"),
                        "content": clean_content,
                        "type": "page",
                        "labels": ",".join(labels)  # Convert array to comma-separated string
                    })
    
    # Process blogs if requested
    if include_blogs and "blogpost" in content_result and "results" in content_result["blogpost"]:
        for blog in content_result["blogpost"]["results"]:
            blog_id = blog.get("id")
            if blog_id:
                # Get blog content
                blog_url = f"{confluence_url}/rest/api/content/{blog_id}?expand=body.storage,metadata.labels"
                blog_data = make_request(blog_url, username, api_token)
                
                if "error" not in blog_data:
                    # Extract content and labels
                    content = blog_data.get("body", {}).get("storage", {}).get("value", "")
                    clean_content = html_to_text(content)
                    
                    # Skip empty blogs
                    if not clean_content or clean_content.strip() == "":
                        continue
                    
                    # Extract labels
                    labels = []
                    if "metadata" in blog_data and "labels" in blog_data["metadata"] and "results" in blog_data["metadata"]["labels"]:
                        for label in blog_data["metadata"]["labels"]["results"]:
                            if "name" in label:
                                labels.append(label["name"])
                    
                    # Add to items
                    items.append({
                        "id": blog_data.get("id"),
                        "title": blog_data.get("title", "Untitled"),
                        "content": clean_content,
                        "type": "blog",
                        "labels": ",".join(labels)  # Convert array to comma-separated string
                    })
    
    # Convert the items list to a JSON string
    items_json = json.dumps(items)
    
    # Return the items as a string value
    print(json.dumps({"items": items_json}))

if __name__ == "__main__":
    main()