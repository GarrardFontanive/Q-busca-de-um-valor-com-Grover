namespace AD2Grover {
    import Std.Convert.*;
    import Std.Measurement.MResetEachZ;

    // Busca classica: devolve o indice e a quantidade de comparacoes.
    function BuscaLinear(dados : Int[], procurado : Int) : (Int, Int) {
        mutable comparacoes = 0;
        for indice in 0..Length(dados) - 1 {
            comparacoes += 1;
            if dados[indice] == procurado {
                return (indice, comparacoes);
            }
        }
        return (-1, comparacoes);
    }

    function ValidarDados(dados : Int[], procurado : Int) : Unit {
        if Length(dados) != 16 {
            fail "Este exemplo usa exatamente 16 valores.";
        }
        if procurado < 0 or procurado > 127 {
            fail "O valor procurado deve estar entre 0 e 127.";
        }
        for i in 0..15 {
            if dados[i] < 0 or dados[i] > 127 {
                fail "Cada valor deve estar entre 0 e 127.";
            }
            for j in i + 1..15 {
                if dados[i] == dados[j] {
                    fail "Use valores distintos neste exemplo.";
                }
            }
        }
    }

    // Converte o padrao escolhido em todos-1, invertendo os bits zero.
    // Convencao: registro[0] representa o bit menos significativo.
    operation InverterBitsZero(padrao : Int, registro : Qubit[]) : Unit is Adj + Ctl {
        for bit in 0..Length(registro) - 1 {
            if (padrao &&& (1 <<< bit)) == 0 {
                X(registro[bit]);
            }
        }
    }

    // Consulta reversivel da tabela: |i>|v> -> |i>|v XOR dados[i]>.
    // O circuito percorre os 16 registros ao construir cada consulta.
    // Esse custo existe: uma chamada ao oraculo NAO equivale a uma porta.
    operation CarregarTabela(dados : Int[], indice : Qubit[], valor : Qubit[])
        : Unit is Adj + Ctl {
        for posicao in 0..15 {
            within {
                InverterBitsZero(posicao, indice);
            } apply {
                for bit in 0..6 {
                    if (dados[posicao] &&& (1 <<< bit)) != 0 {
                        Controlled X(indice, valor[bit]);
                    }
                }
            }
        }
    }

    // Inverte a fase apenas dos indices cujo valor atende a consulta.
    // Nao recebe nem calcula classicamente o indice correto da resposta.
    operation MarcarValor(dados : Int[], procurado : Int, indice : Qubit[]) : Unit {
        use valor = Qubit[7];
        within {
            CarregarTabela(dados, indice, valor);
            InverterBitsZero(procurado, valor);
        } apply {
            Controlled Z(valor[0..5], valor[6]);
        }
        // within/apply desfaz o carregamento e devolve valor a |0000000>.
    }

    // Reflexao que amplifica a amplitude marcada (ate uma fase global).
    operation Difundir(indice : Qubit[]) : Unit {
        within {
            for q in indice {
                H(q);
                X(q);
            }
        } apply {
            Controlled Z(indice[0..2], indice[3]);
        }
    }

    operation BuscarComGrover(dados : Int[], procurado : Int, iteracoes : Int) : Int {
        if iteracoes < 0 {
            fail "O numero de iteracoes nao pode ser negativo.";
        }
        use indice = Qubit[4];
        for q in indice {
            H(q);
        }
        for rodada in 1..iteracoes {
            MarcarValor(dados, procurado, indice);
            Difundir(indice);
        }
        // Os quatro qubits codificam os 16 indices, e nao toda a tabela.
        return ResultArrayAsInt(MResetEachZ(indice));
    }

    operation ExecutarLote(
        dados : Int[], procurado : Int, iteracoes : Int, repeticoes : Int
    ) : (Int[], Int) {
        ValidarDados(dados, procurado);
        if repeticoes <= 0 {
            fail "Use pelo menos uma repeticao.";
        }
        mutable contagens = [0, size = 16];
        mutable acertos = 0;
        for tentativa in 1..repeticoes {
            let indice = BuscarComGrover(dados, procurado, iteracoes);
            contagens w/= indice <- contagens[indice] + 1;
            // Verificacao classica posterior: medir um candidato nao garante acerto.
            if dados[indice] == procurado {
                acertos += 1;
            }
        }
        return (contagens, acertos);
    }

    @EntryPoint()
    operation Main() : Unit {
        let dados = [40, 10, 70, 5, 25, 60, 90, 15, 30, 50, 65, 80, 95, 20, 55, 85];
        let procurado = 55;
        let repeticoes = 200;
        ValidarDados(dados, procurado);

        Message("BUSCA CLASSICA E QUANTICA - SIMULACAO IDEAL");
        Message($"Dados: {dados}");
        Message($"Valor procurado: {procurado}");

        let (indiceLinear, comparacoes) = BuscaLinear(dados, procurado);
        Message($"Busca linear: indice {indiceLinear}; {comparacoes} comparacoes.");
        Message("O indice da busca linear nao e fornecido ao algoritmo quantico.");

        for iteracoes in [0, 3, 6] {
            let (contagens, acertos) = ExecutarLote(
                dados, procurado, iteracoes, repeticoes
            );
            let percentual = 100.0 * IntAsDouble(acertos) / IntAsDouble(repeticoes);
            Message($"--- {iteracoes} iteracoes por tentativa ---");
            Message($"Acertos: {acertos}/{repeticoes} ({percentual}%)");
            Message($"Contagens por indice (0 a 15): {contagens}");
            Message($"Chamadas ao oraculo neste lote: {iteracoes * repeticoes}");
        }

        Message("3 iteracoes amplificam a resposta; 6 ultrapassam o primeiro maximo.");
        Message("Contar consultas nao mede tempo real nem quantidade total de portas.");
    }
}
