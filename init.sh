#!/bin/bash

# Diretório onde estão localizados os scripts (Redefina caso necessário)
# Você também pode executar os scripts um a um localizados na pastas scripts, 
# caso queira ter mais controle da execução.
script_dir="./scripts"

# Verifica se o diretório existe
if [ -d "$script_dir" ]; then
    # Define o diretório de trabalho
    cd "$script_dir"

    # Itera sobre os arquivos na pasta por ordem alfabética
    for script in $(ls -1v *.sh); do
        # Verifica se o arquivo é executável
        if [ -x "$script" ]; then
            echo "Executando o script: $script"
            ./"$script"
        else
            echo "O script $script não é executável. Tornando-o executável..."
            chmod +x "$script"
            ./"$script"
        fi
    done
else
    echo "O diretório $script_dir não existe."
fi
