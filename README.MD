
# Instalação do Humhub na nuvem da AWS
O projeto tem apenas intuito didático, devendo ser seguido de forma cuidadosa.

## O que é HumHub?​
HumHub é uma plataforma de rede social de código aberto com uma ampla variedade de casos de uso como intranet social, comunidade ou plataforma de colaboração. O HumHub consiste em um aplicativo central, que pode ser estendido por meio de módulos adicionais e ajustado às suas necessidades por meio de diversas opções de configuração.

## Autores

- [@v1ct0rbr](https://www.github.com/v1ct0rbr)


## Requisitos Mínimos
- Na sua infra estrutura deve haver dois buckets: um para configurações e outro para arquivos
- Copie o arquivo BaseFileHelper.php para o bucket de configurações
- Deve haver pelo menos uma instância EC2. O tipo e quantidade (se for utilizar balanceamento de carga) depende do quanto você deseja escalar a aplicação.
- Também devem estar ativos serviços de RDS (MariaDB compatível com o Humhub) e Elasticache (utilizando Redis) 

## Instalação
    1. Copie seus arquivos para o EC2 através dos mecanismos que desejar
    2. Inicialize a execução dos scripts através do arquivo init.sh (Ou execute manualmente cada script presente na pasta "scripts" de forma ordenada para mais controle)
    3. Se o arquivo init.sh não for executável, rode o comando "chmod +x init.sh"
    4. Depois da aplicação configurada crie uma imagem do EC2 e no userdata (dados do usuário) copie e cole o conteúdo do arquivo user_data.example.sh (alterando as informações das variáveis de acordo com suas configurações). Dessa forma você consegue utilizar a imagem para configurações de auto scaling.
    5. Caso seja do interesse, você pode controlar a atualzação das imagens através do IMAGE BUILDER para automatizar o processo.
    6. testes de conexão opcionais podem ser feitos através do arquivos optional_test_db_redis.sh presente na pasta tests.

    


    
## Screenshots

### Estrutura utilizada (Não recomendado)
![estrutura](https://raw.githubusercontent.com/v1ct0rbr/humhub-aws-s3fs/main/images/diagrama_v3.drawio.png?token=GHSAT0AAAAAACIYJVZKE3LZMQQLUYYNWRYUZJOQILA)

### Ambiente funcionando
![Ambiente](https://raw.githubusercontent.com/v1ct0rbr/humhub-aws-s3fs/main/images/tela_humhub01.png?token=GHSAT0AAAAAACIYJVZKBUVQJJ22CSXOTKJ6ZJOQJJQ)
## Melhorias almejadas

O projeto foi feito inicialmente para armazenar os arquivos de trabalho no S3 utilizando o S3FS (O que não é recomendado, pois há muita concorrência e disparo de funções da API que encarecem o valor de utilização do serviço e diminuem a performance). Portanto é interessante que se utilize o EFS para compartilhar os arquivos corretamente entre as instâncias. Não tinha muito conhecimento disso quando estava estudando... :(
    


![Logo](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/th5xamgrr6se0x5ro4g6.png)

