<h2>Uma Proposta de Mecanismo de Alocação de Recursos Visando Conciliar Escalabilidade e Engajamento em Transmissões Adaptativas Ao Vivo</h2>

<b>1 – Introdução</b>

O presente conjunto de scripts visa a simulação de realocação de recursos em uma transmissão adaptativa ao vivo, com o objetivo de aumentar a escalabilidade e economia de recursos reduzindo o impacto de restrições de recursos sobre o engajamento dos clientes

<b>2 – Descrição dos arquivos</b>

<ul>
<li>Modo aumento de engajamento: o simulador age identificando clientes prestes a sair e rearranja sua adaptação para tentar mitigar o abandono.</li>
    <ul>
      <li>simulation_v4_engagement.R: simulador associado ao previsor para alocação e previsão de engajamento</li>
      <li>simulation_v4_engagement_rand.R: simulador associado à previsão e alocação aleatória</li>
    </ul>
</ul>

<ul>
<li>Modo economia de recursos: o simulador age identificando clientes que irão permanecer e determina um regime de adaptação mais econômico mas que potencialmente perserve o engajamento.</li>
    <ul>
      <li>simulation_v4_band.R: simulador associado ao previsor para alocação e previsão de engajamento</li>
      <li>simulation_v4_band_rand.R: simulador associado à previsão e alocação aleatória</li>
    </ul>
</ul>

<b>3 – Execução do mecanismo</b>

Para executar o mecanismo, é necessário copiar o dataset de teste (<b>dataset.db</b>) e a tabela de candidatas (<b>chainEvaluationList.csv</b> e <b>chainEvaluationListRand.csv</b>) para o diretório <b>slices</b>. Além disso, uma cópia idêntica do <b>dataset.db</b> deve ficar na pasta <b>bases_sinteticas</b>. Quando o simulador executa, ele armazena na cópia de <b>dataset.db</b> da pasta <b>bases_sinteticas</b> as modificações na alocação feitas nos clientes da base original, que está no diretório <b>slices</b>.

Cada versão do simulador terá uma cópia de <b>dataset.db</b> no diretório <b>bases_sinteticas</b>, cada uma com um nome específico de cada versão do simulador:
<ul>
    <li>dataset_eng.db para simulation_v4_engagement.R</li>
    <li>dataset_eng_rand.db para simulation_v4_engagement_rand.R</li>
    <li>dataset_band.db para simulation_v4_band.R</li>
    <li>dataset_band_rand.db para simulation_v4_band_rand.R</li>
</ul>

O simulador executa por meio do comando Rscript <nome_do_simulador.R>. 

<b>4 – Análise dos resultados</b>

Ao final da execução será possível rodar queryes SQL nos arquivos DB para fazer a comparação entre os dados históricos e sintéticos em cada simulador. Os arquivos são do banco de dados SQLite e podem ser examinados pelo SQLite Studio.

<ul>
  <li>sessionId: identificador de sessão</li>
  <li>SliceNumber: número da janela dentro de uma sessão</li>
  <li>SegmentNumber: quantidade de segmentos da janela</li>
  <li>device e OS: dispositivo e plataforma</li>
  <li>bcastMinute: minuto dentro da transmissão em que a janela foi gerada</li>
  <li>adppos e adpneg: numero de adaptações positivas e negativas</li>
  <li>nstalls: numero de congelamentos</li>
  <li>avgBitrate: quantidade de kilobits gastos na janela</li>
  <li>q264 a q3127: quantidade de segmentos de cada bitrate</li>
  <li>q264_264 a q3127_3127: matriz de transições absoluta</li>
  <li>nextXminute: variavel binário que indica se vai permanecer pelos próximos X minutos</li>
  <li>remEngagement: fração do tempo restante de permanência</li>
  <li>estBand: bitrate registrado na janela em Kbps</li>
</ul>

