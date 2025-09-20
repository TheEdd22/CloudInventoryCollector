# Cloud Inventory Collector

Projeto de coleta automatizada de dados de instâncias em múltiplos provedores de nuvem (Azure, AWS, GCP, OCI), com orquestração em Python e armazenamento centralizado em banco SQL.

## Tecnologias utilizadas
- PowerShell (Azure)
- Bash (Linux via SSH)
- Python (orquestração com SDKs)
- SQL Server / PostgreSQL
- Azure, AWS, GCP, OCI

## Estrutura do projeto
- `azure/`: Scripts PowerShell para provisionamento e limpeza no Azure
- `aws/`, `gcp/`, `oci/`: Scripts para os demais provedores
- `orchestrator/`: Código Python para coleta e integração com banco
- `sql/`: Scripts de criação de schema e tabelas
- `docs/`: Documentação técnica e arquitetura

## Como começar
1. Execute o script de provisionamento em `azure/scripts/Provisionamento_Azure.ps1`
2. Acesse as VMs e valide conectividade
3. Inicie a orquestração com o script Python (em breve)
