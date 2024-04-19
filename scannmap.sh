#!/bin/bash

# Função para imprimir o cabeçalho
print_header() {
    echo "=================================="
    echo "        BEM VINDO AO SCAN MASTER"
    echo "=================================="
}

# Função para realizar o escaneamento com o Nmap e imprimir os resultados
perform_scan() {
    target=$1
    output_file="${target}_resultados_escaneamento.txt"

    echo "Escaneando o alvo: $target"
    echo ""

    # Comando do Nmap para realizar o escaneamento e obter informações sobre o sistema operacional e serviços
    echo "1. Informações do Sistema Operacional e Serviços:"
    nmap -A $target | tee $output_file

    # Verificando se há uma página web
    echo ""
    echo "2. Pesquisa por números de telefone e e-mails na página web (se disponível):"
    curl -s http://$target | grep -Eo '[0-9]{2,4}[-\s]*[0-9]{4,5}|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}' | tee -a $output_file

    echo ""
    echo "3. Informações WHOIS (se disponível):"
    whois $target | tee -a $output_file

    echo ""
    echo "4. Vulnerabilidades (se disponíveis):"
    # Comando para verificar vulnerabilidades usando o Nmap
    nmap --script vuln $target | tee -a $output_file
}

# Função para realizar a enumeração de diretórios e arquivos com o Gobuster e imprimir os resultados
perform_gobuster() {
    target=$1
    directory=$2
    output_file="${target}_resultados_gobuster.txt"

    echo "Executando o Gobuster para enumerar diretórios e arquivos em http://$target$directory"
    echo ""

    # Executando o Gobuster e filtrando apenas os resultados com código de status 200
    gobuster dir -u http://$target$directory -w /usr/share/wordlists/dirb/common.txt /usr/share/wordlists/dirb/big.txt -t 50 | grep -Eo '[0-9]{3}\s*Found.*' | tee $output_file
}

# Função para realizar o ARP scan e imprimir os resultados
perform_arpscan() {
    echo "Executando o ARP scan para encontrar dispositivos na rede..."
    echo ""

    # Executando o ARP scan na rede local
    sudo arp-scan --localnet
}

# Função principal para executar o script
main() {
    read -p "Escolha o tipo de alvo (1 para local, 2 para remoto): " target_type

    if [[ $target_type == "1" ]]; then
        local_ip=$(hostname -I | cut -d' ' -f1)
        echo "Seu endereço IP local é: $local_ip"
        perform_arpscan
        read -p "Digite o endereço IP do alvo: " target
    elif [[ $target_type == "2" ]]; then
        read -p "Digite o endereço IP ou hostname do alvo: " target
    else
        echo "Opção inválida. Escolha '1' para local ou '2' para remoto."
        exit 1
    fi

    print_header
    perform_scan $target

    perform_gobuster $target "/"

    echo ""
    echo "Os resultados foram salvos em ${target}_resultados_escaneamento.txt e ${target}_resultados_gobuster.txt"
}

# Chamada da função principal
main

