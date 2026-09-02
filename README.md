# Weather Explorer

Aplicativo de previsão do tempo em Flutter, com dados da OpenWeatherMap. Mostra o
clima atual e a previsão dos próximos dias das cidades que você escolher, guarda a
lista localmente e continua exibindo o último resultado quando você está sem
internet.

## Funcionalidades

- Clima atual: temperatura, sensação térmica, condição, vento, umidade e pressão
- Previsão dos próximos dias a partir dos blocos de 3 em 3 horas da API
- Horários de nascer e pôr do sol
- Lista de cidades favoritas, salva no aparelho
- Cache em SQLite: o último clima consultado aparece mesmo offline
- Animações de fundo que acompanham a condição do tempo e o período do dia

## Requisitos

- Flutter 3.41 ou superior (o Dart 3.11 vem junto)
- Uma chave da OpenWeatherMap — o plano gratuito basta:
  <https://openweathermap.org/api>

## Como rodar

```bash
git clone https://github.com/RIGOandre/OpenW_Api.git
cd OpenW_Api
flutter pub get
```

A chave da API não fica escrita no código. Ela entra por `--dart-define`, o que
permite publicar o repositório sem expor a credencial. Copie o exemplo e coloque a
sua chave nele:

```bash
cp .env.example .env
```

```
OPENWEATHER_API_KEY=sua_chave_aqui
```

O arquivo `.env` está no `.gitignore` e não vai para o repositório. Com ele pronto:

```bash
flutter run --dart-define-from-file=.env              # aparelho ou emulador
flutter run -d windows --dart-define-from-file=.env   # desktop
flutter run -d chrome  --dart-define-from-file=.env   # web
```

Se preferir não usar arquivo, passe a chave direto:

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=sua_chave_aqui
```

Sem chave configurada o app abre, mas as consultas falham com aviso na tela —
`WeatherService.hasApiKey` é o que sinaliza isso.

## Testes

```bash
flutter test
```

Cobrem os formatadores de texto e a leitura do JSON da OpenWeatherMap: arredondamento
de temperatura, conversão do vento para km/h, deslocamento de horário para o fuso da
cidade e o resumo dos próximos dias a partir dos blocos de 3 em 3 horas.

## Estrutura

```
lib/
├── main.dart                       tela principal e navegação
├── theme/
│   └── app_theme.dart              paleta, gradientes e o ThemeData do app
├── models/
│   ├── weather_model.dart          clima atual, previsão e resumo diário
│   └── app_exception.dart          erros tipados (rede, chave, cidade não achada)
├── services/
│   ├── weather_service.dart        cliente da OpenWeatherMap
│   ├── weather_repository.dart     junta clima e previsão, com cache local
│   ├── city_service.dart           cidades favoritas
│   └── connectivity_service.dart   checagem de conexão antes da requisição
├── widgets/
│   ├── custom_drawer.dart          menu lateral e gerência de cidades
│   ├── forecast_widget.dart        previsão dos próximos dias
│   ├── info_cards.dart             cartões de vento, umidade, sol
│   ├── weather_loading_widget.dart carregamento com shimmer
│   └── weather_error_view.dart     estados de erro
├── utils/
│   ├── formatters.dart             temperatura, datas e textos
│   └── weather_assets.dart         código da API → animação em assets/images
└── db/
    └── database_helper.dart        cache SQLite
```

As animações de clima ficam em `assets/images`, uma para cada condição, com versões
de dia e de noite.

## Plataformas

O projeto tem as pastas de Android, iOS, Windows, Linux, macOS e web. O
`sqflite_common_ffi` está incluído para o cache funcionar também no desktop.

## Licença

MIT — veja [LICENSE](LICENSE).

Feito por [RIGOandre](https://github.com/RIGOandre).
