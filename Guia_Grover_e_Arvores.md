# Q#: busca de um valor com Grover

Este exemplo amplia o estudo da linguagem Q# com uma tarefa de busca. O pacote implementa **busca linear e busca quântica com Grover**. Árvores rubro-negras entram como comparação conceitual; este código não implementa a árvore nem suas rotações.

## Executar no ambiente que você já configurou

1. Extraia este pacote em uma pasta própria.
2. Abra essa pasta no VS Code e abra `Main.qs`.
3. Clique em **Run**, acima de `Main`, como no exemplo do par de Bell.
4. Observe os resultados dos lotes com 0, 3 e 6 iterações.

O programa usa o simulador local com perfil **Unrestricted**. A alternativa pelo terminal é a mesma do pacote anterior: criar e ativar um ambiente virtual, instalar `requirements.txt` e executar `python executar.py`.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python executar.py
```

O experimento e a contagem das respostas estão em Q#. Python é apenas a alternativa para iniciar o QDK. A compilação e as verificações foram feitas com o QDK 1.32.3; o registro está em `Verificacao.txt`.

## O problema

Procuramos o valor **55** nesta lista sem ordenação:

```text
[40, 10, 70, 5, 25, 60, 90, 15, 30, 50, 65, 80, 95, 20, 55, 85]
```

A resposta é o **índice 14**, contando a partir de zero. A busca linear encontra esse índice depois de 15 comparações. Ela serve de referência e não fornece a resposta ao circuito quântico.

Grover usa quatro qubits para representar os **16 índices candidatos**. Ele ainda usa sete qubits auxiliares para consultar os valores da tabela. O exemplo exige exatamente 16 valores distintos, entre 0 e 127. Para estudar o caso de uma solução, escolha como alvo um valor presente na lista.

## O que acontece na busca quântica

1. As portas `H` preparam os índices em uma superposição uniforme.
2. O oráculo consulta o valor associado a cada índice de forma reversível e muda a fase dos estados que correspondem ao valor procurado.
3. O difusor transforma essa marcação de fase em amplificação da probabilidade de medir a resposta.
4. Repetimos oráculo e difusor o número escolhido de vezes.
5. Medimos um índice e verificamos classicamente se seu valor é o procurado.

Essa organização segue o algoritmo de Grover descrito em [1–2]. Uma iteração é uma aplicação do oráculo seguida do difusor. Ela contém várias portas, não apenas uma operação física.

O oráculo não recebe o índice 14. Ele recebe a lista e o valor 55, carrega o registro correspondente ao índice quântico, compara o valor e desfaz o carregamento. A lista inteira é codificada no circuito de consulta. Isso tem custo e é explicado abaixo.

## Por que testar 0, 3 e 6 iterações?

Para 16 candidatos e uma única solução, a probabilidade ideal depois de r iterações é:

$$
P_r=\sin^2\!\left((2r+1)\arcsin\frac{1}{4}\right).
$$

| Iterações por tentativa | Probabilidade ideal de acertar | Interpretação |
| --- | ---: | --- |
| 0 | 6,25% | Medição da superposição uniforme, sem amplificação. |
| 3 | Aproximadamente 96,13% | Próximo do primeiro máximo de probabilidade. |
| 6 | Aproximadamente 2,04% | A amplificação passou desse máximo e a probabilidade caiu. |

Mais iterações nem sempre ajudam. A probabilidade oscila. Esse efeito é uma parte interessante do funcionamento do algoritmo, e não um erro do programa.

Cada configuração é executada 200 vezes. São 200 buscas novas, usadas para observar a frequência de acerto. No lote com três iterações, são **600 chamadas ao oráculo no total**, além de 200 verificações clássicas dos candidatos. Não confunda uma tentativa de busca com o lote usado para coletar estatísticas.

Uma nova execução pode produzir outras contagens. Compare as frequências com as probabilidades teóricas, sem exigir igualdade exata. Um lote com seis iterações pode inclusive apresentar zero acertos, apesar de a probabilidade ideal ser pequena e não nula.

## A conexão com árvores rubro-negras

Uma árvore rubro-negra é uma árvore de busca binária que mantém condições de balanceamento com cores, rotações e ajustes. Sua organização permite descartar parte das chaves a cada comparação e garante busca em O(log N) no pior caso [3]. Implementar essa estrutura em Q# não transforma suas operações clássicas em operações quânticas.

| Abordagem | Estrutura ou acesso disponível | Custo relevante |
| --- | --- | --- |
| Busca linear | Lista sem um índice de busca | O(N) comparações no pior caso. |
| Árvore rubro-negra já construída | Chaves ordenadas e estrutura balanceada | O(log N) comparações; construir e manter a árvore tem custo. |
| Grover, uma solução | Acesso coerente a um oráculo de verificação | O(raiz de N) chamadas ao oráculo para probabilidade de sucesso constante. |

Esses custos usam premissas e unidades diferentes. O(log N) cresce mais lentamente que O(raiz de N), e a árvore aproveita uma organização que não faz parte do modelo de busca não estruturada de Grover. Portanto, não apresente Grover como um substituto universal ou uma melhoria automática da árvore.

Uma discussão interessante para a AD2 é: **em que situações vale organizar os dados previamente e em que situações temos apenas um verificador de candidatos?** Isso conecta Estrutura de Dados a paradigmas e algoritmos quânticos sem confundir os problemas.

## O custo que não pode ficar escondido

Neste exemplo, `CarregarTabela` percorre os 16 registros para definir portas controladas. Para uma família maior de tabelas, esse carregamento direto tem custo que cresce com o tamanho da tabela e a quantidade de bits por valor. Cada chamada ao oráculo inclui carregamento, comparação de fase e descarregamento.

A checagem clássica de tamanho, faixa e duplicatas também tem custo de preparação. As contagens impressas não incluem esses custos como se fossem comparações simples.

O ganho teórico de Grover refere-se ao **número de consultas ao oráculo no modelo apropriado**. O pacote demonstra a amplificação de amplitudes e não estabelece que essa implementação de tabela explícita tem menor tempo total que a busca clássica. O simulador, por sua vez, roda em um computador clássico. Não use o tempo de execução no notebook como prova de aceleração quântica.

## Como ler o código

| Rotina | Função no programa |
| --- | --- |
| `Main` | Define lista, alvo e experimentos; mostra resultados. |
| `BuscaLinear` | Busca clássica de referência, com contagem de comparações. |
| `ValidarDados` | Verifica as restrições deste exemplo didático. |
| `InverterBitsZero` | Converte um padrão binário em todos-1 usando portas X. |
| `CarregarTabela` | Consulta reversível: o índice controla a escrita dos bits do valor. |
| `MarcarValor` | Marca por fase os índices que atendem ao critério. |
| `Difundir` | Realiza a reflexão usada na amplificação de amplitudes. |
| `BuscarComGrover` | Prepara, repete as transformações e mede um índice. |
| `ExecutarLote` | Repete buscas completas e verifica os candidatos medidos. |

Os recursos da linguagem incluem `function`, `operation`, `let`, `mutable`, tipos, arrays, laços, decisões, falhas, chamadas controladas e operações reversíveis. No bloco `within { ... } apply { ... }`, o QDK executa a preparação, o bloco de aplicação e a inversa da preparação. Essa inversa limpa os qubits auxiliares sem apagar a marcação de fase desejada.

O código adota `registro[0]` como o bit menos significativo ao converter resultados para inteiros. Um índice encontrado é uma posição da lista; não é diretamente o valor armazenado nela.

## O que experimentar e registrar

- Capture a execução padrão e explique o índice 14 e as 15 comparações clássicas.
- Compare as frequências de acerto para 0, 3 e 6 iterações.
- Troque o alvo para outro valor presente e execute novamente.
- Reordene os mesmos 16 valores. O índice da resposta deve acompanhar a nova posição.
- Para investigar flutuações, aumente `repeticoes` de 200 para 1000; a simulação levará mais tempo.

Se o alvo não existir, a busca linear retorna -1. Grover ainda mede índices, mas a verificação posterior rejeita todos. Isso não é uma garantia geral de detecção de ausência por amostragem: o algoritmo aqui foi configurado para estudar o caso de uma única solução.

Na seção de exemplo prático da AD2, apresente o problema, o código comentado, suas capturas, a interpretação dos resultados e as limitações da comparação. Use a árvore rubro-negra na discussão de estruturas de acesso aos dados. Não afirme ter implementado a árvore neste pacote.

## Referências

1. MICROSOFT. **Implement Grover's search algorithm in Q#**. https://learn.microsoft.com/en-us/azure/quantum/tutorial-qdk-grovers-search
2. MICROSOFT. **Theory of Grover's search algorithm**. https://learn.microsoft.com/en-us/azure/quantum/concepts-grovers
3. SEDGEWICK, Robert; WAYNE, Kevin. **Balanced Search Trees**. Algorithms, 4th edition. Princeton University. https://algs4.cs.princeton.edu/33balanced/
4. MICROSOFT. **ResultArrayAsInt function**. https://learn.microsoft.com/en-us/qsharp/api/qsharp-lang/std.convert/resultarrayasint

Fontes consultadas em 28/09/2026. A expressão da probabilidade e os resultados do circuito foram confrontados numericamente durante a verificação deste pacote.

## Apoio de IA

Este código e este roteiro foram preparados com apoio do ChatGPT e verificados no simulador do QDK. Declare o apoio efetivamente utilizado no apêndice exigido pela AD2, execute o exemplo, registre suas modificações e escreva sua própria análise.
