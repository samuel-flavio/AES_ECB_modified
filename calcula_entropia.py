import math
import os
from collections import Counter

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
        # 'Imagens/VistaAereaSP.bin',
        # 'Imagens/Resultado AES_ECB/resultado_fpga_VistaAereaSP.bin',
        # 'Imagens/CisnePretoBranco.bin',
        # 'Imagens/Resultado AES_ECB/resultado_fpga_CisnePretoBranco.bin',
        # 'Imagens/FrutaPadraoConstanteCor.bin',
        # 'Imagens/Resultado AES_ECB/resultado_fpga_FrutaPadraoConstanteCor.bin'
        'Imagens/ImagemTrabalhoModeloProprioPB.bin',
        'Imagens/resultado_fpga_ImagemTrabalhoModeloProprioPB.bin',
        'Imagens/resultado_python_ImagemTrabalhoModeloProprioPB.bin'
    ]
    
    print("--- Cálculo de Entropia de Shannon ---")
    for arquivo in arquivos_para_testar:
        entropia = calcular_entropia_shannon(arquivo)
        if entropia is not None:
            print(f"Entropia de {arquivo}: {entropia:.8f} bits/byte")
