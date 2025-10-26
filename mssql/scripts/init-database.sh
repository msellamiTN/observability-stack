#!/bin/bash
# =============================================
# MS SQL Server Database Initialization Script
# Executes all SQL scripts in order
# =============================================

echo "Waiting for SQL Server to be ready..."
sleep 30

echo "Starting database initialization..."

# Execute SQL scripts in order
for script in /docker-entrypoint-initdb.d/*.sql; do
    if [ -f "$script" ]; then
        echo "Executing: $(basename $script)"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -i "$script"
        
        if [ $? -eq 0 ]; then
            echo "✓ $(basename $script) executed successfully"
        else
            echo "✗ Error executing $(basename $script)"
            exit 1
        fi
    fi
done

echo "Database initialization completed successfully!"
