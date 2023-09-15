BD_INSTALL_REQUIRED=false
REDIS_TESTED=false

verify_db(){
    
    local result=$(mysqlshow -h "$HUMHUB_DB_HOST" -P "$HUMHUB_DB_PORT" -u "$HUMHUB_DB_USER" -p"$HUMHUB_DB_PASSWORD" "$HUMHUB_DB_NAME" 2> /tmp/dbresults)
    
    # Verifica se o banco de dados existe e se há tabelas dentro dele
    if [[ $result == *"$HUMHUB_DB_NAME"* ]]; then
        echo "O banco de dados '$HUMHUB_DB_NAME' existe."
        
        if [[ $result == *"Tables in $HUMHUB_DB_NAME"* ]]; then
            echo "Existem tabelas no banco de dados '$HUMHUB_DB_NAME'."
        else
            echo "O banco de dados '$HUMHUB_DB_NAME' está vazio (sem tabelas internas)."
            BD_INSTALL_REQUIRED=true;
        fi
    else
        echo "O banco de dados '$HUMHUB_DB_NAME' não existe ou não é acessível em '$HUMHUB_DB_HOST'."
        BD_INSTALL_REQUIRED=true;
    fi
}
echo 'Verificando banco de dados..............................................20%'
verify_db