import csv
import math
import os
from collections import Counter

# Configurações para o CSV de saída (fora do contexto do git)
CSV_OUTPUT_PATH = r'C:\caminho\para\seu\arquivo_entropia.csv'  # Altere para o caminho desejado
MODO_ENCRIPTACAO = 'AES_ECB'  # Atualize para AES_ECB ou AES_Counter quando necessário

def calcular_entropia_shannon(caminho_arquivo):
    """
    Calcula a entropia de Shannon dos bytes de um arquivo binário.
    Quanto mais próximo de 8.0, mais aleatórios (encriptados/comprimidos) são os dados.
    """
    if not os.path.exists(caminho_arquivo):
        print(f"Aviso: Arquivo '{caminho_arquivo}' não encontrado.")
        return None
        
    with open(caminho_arquivo, 'rb') as f:
        dados = f.read()
        
    tamanho_dados = len(dados)
    if tamanho_dados == 0:
        return 0.0
        
    # Conta a frequência de cada valor de byte (0 a 255) existente no arquivo
    frequencias = Counter(dados)
    
    entropia = 0.0
    for freq in frequencias.values():
        probabilidade = freq / tamanho_dados
        entropia -= probabilidade * math.log2(probabilidade)
        
    return entropia

if __name__ == "__main__":
    # Lista de arquivos baseada nas suas imagens presentes na pasta Imagens/
    arquivos_para_testar = [
        'Imagens/VistaAereaSP.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_fpga_VistaAereaSP.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_python_VistaAereaSP.bin',
        'Imagens/CisnePretoBranco.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_fpga_CisnePretoBranco.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_python_CisnePretoBranco.bin',
        'Imagens/FrutaPadraoConstanteCor.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_fpga_FrutaPadraoConstanteCor.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_python_FrutaPadraoConstanteCor.bin',
        'Imagens/ImagemTrabalhoModeloProprio.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_fpga_ImagemTrabalhoModeloProprio.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_python_ImagemTrabalhoModeloProprio.bin',
        'Imagens/ImagemTrabalhoModeloProprioPB.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_fpga_ImagemTrabalhoModeloProprioPB.bin',
        'Imagens/Resultado AES_KeyAgillity/resultado_python_ImagemTrabalhoModeloProprioPB.bin'
    ]
    
    # Verifica se o CSV já existe para adicionar o cabeçalho se for a primeira execução
    arquivo_existe = os.path.exists(CSV_OUTPUT_PATH)
    
    print("--- Cálculo de Entropia de Shannon ---")
    
    try:
        # Abre o arquivo em modo 'a' (append), que garante a inserção após a última linha
        with open(CSV_OUTPUT_PATH, mode='a', newline='', encoding='utf-8') as csv_file:
            writer = csv.writer(csv_file)
            
            if not arquivo_existe:
                writer.writerow(['modo_de_encriptacao', 'nome_do_arquivo', 'entropia'])
                
            for arquivo in arquivos_para_testar:
                entropia = calcular_entropia_shannon(arquivo)
                if entropia is not None:
                    nome_arquivo = os.path.basename(arquivo)
                    # Verifica se o arquivo é um resultado ou o original para preencher a coluna corretamente
                    modo = MODO_ENCRIPTACAO if 'resultado' in nome_arquivo else 'Original'
                    writer.writerow([modo, nome_arquivo, f"{entropia:.12f}"])
                    print(f"Entropia de {arquivo}: {entropia:.12f} bits/byte -> Salvo no CSV.")
                    
    except Exception as e:
        print(f"Erro ao salvar no arquivo CSV: {e}")
