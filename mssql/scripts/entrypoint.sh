#!/bin/bash
set -e

echo "Starting SQL Server..."
/opt/mssql/bin/sqlservr &

# Attendre que SQL Server soit prêt
echo "Waiting for SQL Server to be ready..."
for i in {1..60}; do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" &> /dev/null; then
        echo "SQL Server is ready!"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 1
done

# Exécuter les scripts d'initialisation
echo "Initializing database..."
for script in /docker-entrypoint-initdb.d/*.sql; do
    if [ -f "$script" ]; then
        echo "Executing: $(basename $script)"
        /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i "$script"
        
        if [ $? -eq 0 ]; then
            echo "✓ $(basename $script) executed successfully"
        else
            echo "✗ Error executing $(basename $script)"
            exit 1
        fi
    fi
done

echo "Database initialization completed!"

# Garder le conteneur actif
wait
