# Validação de Hardware AES-128 (FPGA vs Python)

Este projeto implementa um sistema de co-simulação e validação em hardware para o algoritmo de criptografia AES-128 (modo ECB). O sistema realiza a encriptação de arquivos binários (imagens) localmente via software e remotamente em uma FPGA via comunicação serial (UART), permitindo a validação de corretude dos dados e a análise de métricas de performance (tempo e ciclos de clock).

## Estrutura do Projeto

Abaixo está a árvore de diretórios e arquivos controlados pelo Git neste repositório:

```text
.
├── README.md
├── aes_dual_output_validator.py
├── calcula_entropia.py
├── aes_top_interface.v
├── (outros arquivos Verilog do projeto...)
└── Imagens/
    ├── CisnePretoBranco.bin
    ├── FrutaPadraoConstanteCor.bin
    ├── vistaAereaSP.bin
    ├── ImagemTrabalhoModeloProprio.bin
    ├── ImagemTrabalhoModeloProprioPB.bin
    └── Resultado AES_ECB/
        ├── resultado_fpga_*.bin
        ├── resultado_python_*.bin
        └── metricas_performance_*.csv
```

## Módulo Topo do Hardware (`aes_top_interface.v`)

Estrutura hierárquica do módulo:

```text
├── aes_top_interface
    ├── uart_rx
    ├── uart_tx
    └── aes_cipher
        ├── key_expansion
        |    ├── rcon_lookup  
        |    └── key_transformation_logic
        |        ├── rotate_word
        |        ├── subbed_word
        |        └── sbox
        |            └── sbox_data.mem
        ├── sub_bytes
        |    └── sbox
        |        └── sbox_data.mem
        ├── shift_rows
        ├── mix_columns
        |    └── xtimes()
        └── add_round_key
```

Este é o arquivo principal (Top-Level) do projeto na FPGA. Ele atua como uma ponte de comunicação entre o computador e o núcleo criptográfico, orquestrando as seguintes instâncias e funcionalidades:

*   **Interface UART (RX/TX):** Instancia os módulos de recepção (RX) e transmissão (TX) serial, configurados para operar na taxa de transmissão (Baud Rate) de 921600. É responsável por receber o bloco de 16 bytes (texto plano) do PC e enviar de volta os 20 bytes da resposta.
*   **Núcleo AES-128 (`aes_cipher`):** Instancia o motor criptográfico de hardware. Ao receber os 16 bytes completos da interface UART, esta instância é ativada por uma máquina de estados (FSM) para realizar a encriptação ECB utilizando a chave pré-definida em hardware.
*   **Contador de Ciclos / Performance:** Instancia um contador de hardware que inicia no primeiro ciclo de processamento do bloco e para quando o dado cifrado está pronto. O valor final (32 bits / 4 bytes) é acoplado ao pacote de resposta.
*   **Máquina de Estados (FSM):** Controla o fluxo de dados. Agrupa os bytes recebidos da UART, aciona o AES, aguarda a finalização (flag `done`), e empacota os 16 bytes cifrados juntamente com os 4 bytes de ciclos de hardware para enviá-los de volta através do TX.

## Validador de Saída Dupla (`aes_dual_output_validator.py`)

Este script em Python é o responsável por injetar os dados de teste no hardware, gerar uma referência (Golden Model) em software, validar a saída da FPGA e extrair métricas. Suas principais etapas são:

1.  **Processamento de Arquivos:** 
    Lê a imagem binária de entrada e aplica um "padding" com zeros no final do arquivo caso o tamanho original não seja um múltiplo exato de 16 bytes, assegurando que não haverá falha no fatiamento dos blocos.

2.  **Referência em Software (Python):** 
    Utiliza a biblioteca PyCryptodome (`Crypto.Cipher.AES`) em modo ECB para encriptar os mesmos blocos de dados de forma nativa e ideal, servindo como base de comparação de corretude (Golden Model).

3.  **Comunicação com a FPGA:** 
    Envia os blocos de texto plano para a porta serial (ex: `COM9`) e aguarda a devolução de um array contendo 20 bytes (16 do Ciphertext + 4 bytes de metadados referentes aos ciclos).

4.  **Validação e Coleta de Métricas:** 
    *   **Corretude:** Verifica de forma autônoma se a cifra obtida da FPGA (`fpga_cipher`) é exatamento igual à cifra obtida no Python (`expected_cipher`).
    *   **Performance:** Calcula os tempos de execução baseados nos ciclos de clock reportados pela FPGA e os compara com os tempos de execução do software e com o Round Trip Time (RTT) da porta serial.

5.  **Geração de Relatórios e Resultados:** 
    Gera três saídas para cada execução:
    *   Arquivo binário com a encriptação feita no Python.
    *   Arquivo binário com a encriptação devolvida pela FPGA.
    *   Um arquivo CSV detalhando o status de erro/sucesso e os tempos associados a cada bloco executado.
