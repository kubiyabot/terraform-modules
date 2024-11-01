# Unity Catalog Operations

## Catalog Structure
1. Organization Pattern
   ```
   workspace
   ├── production_catalog
   │   ├── raw_data
   │   └── processed_data
   ├── development_catalog
   │   ├── sandbox
   │   └── testing
   └── shared_catalog
       ├── reference_data
       └── common_features
   ```

2. Naming Conventions
   ```
   <env>_<domain>_<purpose>
   Example: prod_finance_transactions
   ```

## Security Configuration
1. Access Patterns
   ```sql
   -- Grant catalog access
   GRANT CREATE, USAGE ON CATALOG prod_finance TO `data_engineers`;
   
   -- Schema level permissions
   GRANT SELECT, MODIFY ON SCHEMA prod_finance.transactions TO `analysts`;
   
   -- Table specific access
   GRANT SELECT ON TABLE prod_finance.transactions.customer_data TO `reporting`;
   ```

2. Row-Level Security
   ```sql
   -- Create security function
   CREATE FUNCTION row_filter(region STRING)
   RETURN boolean
   RETURN current_user() IN (
     SELECT user FROM access_control WHERE allowed_region = region
   );
   
   -- Apply to table
   ALTER TABLE customer_data
   SET ROW FILTER row_filter(region);
   ```

## Data Governance
1. Metadata Management
   ```sql
   -- Add table properties
   ALTER TABLE customer_data
   SET TBLPROPERTIES (
     'purpose' = 'Customer transaction history',
     'owner' = 'finance_team',
     'retention' = '7years'
   );
   ```

2. Lineage Tracking
   ```sql
   -- Track data transformations
   CREATE TABLE processed_transactions
   COMMENT 'Derived from raw_transactions with privacy filters'
   AS SELECT /* transformation logic */;
   ```

## Best Practices
1. Data Organization
   - Use consistent naming
   - Implement clear hierarchies
   - Document relationships
   - Version appropriately

2. Access Control
   - Follow least privilege
   - Use groups over users
   - Regular access reviews
   - Audit trail maintenance

3. Performance
   - Optimize partitioning
   - Manage file sizes
   - Monitor query patterns
   - Cache frequently used data 