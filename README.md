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

Para executar o mecanismo, é necessário copiar o dataset de teste (<b>dataset.db</b>) e a tabela de candidatas () para o diretório <b>slices</b>. Além disso, uma cópia idêntica do <b>dataset.db</b> deve ficar na pasta <b>bases_sinteticas</b>. Quando o simulador executa, ele armazena na cópia de <b>dataset.db</b> da pasta <b>bases_sinteticas</b> as modificações na alocação feitas nos clientes da base original, que está no diretório <b>slices</b>.
