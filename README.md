# Weather Explorer 🌤️

<div align="center">

**Aplicativo moderno de previsão do tempo com interface responsiva e funcionalidades avançadas**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)
![OpenWeather](https://img.shields.io/badge/OpenWeather_API-orange?style=for-the-badge&logo=weather&logoColor=white)

</div>

## 🚀 Funcionalidades Principais

### ⭐ Características Destacadas
- **Interface Moderna**: Design Material You com glassmorphism e gradientes
- **Responsividade Completa**: Adaptável a todos os tamanhos de tela
- **Animações Fluidas**: Transições suaves e feedback visual
- **Offline Support**: Cache inteligente e persistência local
- **Multiplataforma**: Android, iOS, Windows, macOS, Linux, Web

### 🌤️ Dados Meteorológicos
- Temperatura atual e sensação térmica
- Condições climáticas detalhadas com ícones animados
- Previsão de 5 dias com probabilidade de chuva
- Informações de vento, umidade e pressão
- Horários precisos do nascer/pôr do sol
- Coordenadas geográficas

## �️ Arquitetura e Melhorias Implementadas

### 📦 Estrutura Modular
```
lib/
├── main.dart                    # Aplicação principal com tema customizado
├── models/                      # Modelos tipados de dados
│   └── weather_model.dart       # WeatherModel e ForecastModel
├── services/                    # Camada de serviços
│   ├── weather_service.dart     # API OpenWeatherMap com tratamento de erros
│   └── city_service.dart        # Gerenciamento persistente de cidades
├── widgets/                     # Componentes reutilizáveis
│   ├── weather_loading_widget.dart  # Loading com shimmer effects
│   ├── error_widget.dart        # Estados de erro elegantes
│   ├── info_cards.dart          # Cards informativos responsivos  
│   ├── forecast_widget.dart     # Widget de previsão avançado
│   └── custom_drawer.dart       # Drawer personalizado moderno
├── utils/                       # Utilitários e formatadores
│   ├── weather_assets.dart      # Mapeamento de ícones climáticos
│   └── formatters.dart          # Formatação de dados e datas
└── db/                          # Persistência otimizada
    └── database_helper.dart     # SQLite com migrações automáticas
```

### 🔧 Melhorias Técnicas

#### **Gerenciamento de Estado**
- Controllers de animação com dispose automático
- Estados de loading, erro e sucesso bem definidos
- Feedback visual em todas as interações do usuário

#### **Performance e Otimização**
- Verificação de conectividade antes das requisições
- Timeouts configuráveis (10 segundos)
- Cache inteligente com SQLite versionado
- Lazy loading de componentes pesados

#### **Tratamento de Erros Robusto**
- Try-catch abrangente em todas as operações
- Mensagens de erro específicas e amigáveis
- Fallbacks automáticos para cenários de falha
- Retry automático com feedback visual

#### **UI/UX Moderna**
- **Material Design 3** com Google Fonts (Poppins)
- **Glassmorphism**: Cards com transparência e blur
- **Gradientes dinâmicos** baseados no período do dia
- **Animações fluidas**: Fade, rotation e shimmer effects
- **Responsividade total**: Grid adaptativo e tipografia escalável

## 🛠️ Tecnologias e Dependências

### **Core Framework**
- **Flutter 3.3+**: Framework multiplataforma
- **Dart**: Linguagem de programação moderna

### **Networking & API**
- **http 1.2+**: Cliente HTTP otimizado
- **connectivity_plus**: Verificação de conectividade
- **OpenWeatherMap API**: Dados meteorológicos precisos

### **Persistência & Storage**
- **sqflite**: Banco SQLite local com migrações
- **shared_preferences**: Configurações do usuário
- **path**: Manipulação de caminhos de arquivo

### **UI & Design**  
- **google_fonts**: Tipografia Poppins moderna
- **shimmer**: Loading states elegantes
- **lottie**: Suporte a animações avançadas (futuro)

### **Utilitários**
- **intl**: Formatação de datas e internacionalização

## 🚀 Configuração e Instalação

### **Pré-requisitos**
- Flutter SDK 3.3.0 ou superior
- Dart SDK incluído com Flutter
- Chave da API OpenWeatherMap ([registre-se gratuitamente](https://openweathermap.org/api))

### **Instalação Rápida**

1. **Clone o repositório**
```bash
git clone https://github.com/RIGOandre/OpenW_Api.git
cd OpenW_Api
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure sua API Key de forma segura**
   - Obtenha sua chave gratuita em [OpenWeatherMap](https://openweathermap.org/api)
   - Abra `lib/services/weather_service.dart`
   - Substitua `static const String _apiKey = '';` pela sua chave
   - ⚠️ **IMPORTANTE**: Nunca faça commit da sua API key real no repositório!

4. **Execute o aplicativo**
```bash
# Para desktop (Windows/macOS/Linux)
flutter run -d windows

# Para mobile (se emulador/device conectado)
flutter run

# Para web
flutter run -d chrome
```

## 📱 Como Usar

### **Navegação Principal**
- **Tela Inicial**: Exibe clima atual da cidade selecionada
- **Menu Lateral**: Gerencie suas cidades favoritas
- **Atualização**: Botão de refresh no AppBar com animação
- **Previsão**: Role para ver previsão detalhada de 5 dias

### **Gerenciamento de Cidades**
- **Adicionar**: Use o botão no drawer para adicionar novas cidades
- **Alternar**: Toque numa cidade para visualizar seu clima
- **Remover**: Use o ícone de lixeira (mínimo 1 cidade obrigatória)
- **Persistência**: Suas cidades são salvas localmente

## 🎨 Features de Design

### **Interface Moderna**
- Material Design 3 com gradientes dinâmicos
- Glassmorphism com cards semi-transparentes
- Tipografia Poppins para legibilidade moderna
- Ícones animados correspondentes às condições climáticas

### **Responsividade Total**
- Grid adaptativo que se ajusta ao tamanho da tela
- Layout fluido que funciona em qualquer resolução
- Touch targets otimizados para mobile e desktop
- Compatível com múltiplas resoluções

## 🔧 Configuração da API

```dart
// lib/services/weather_service.dart
static const String _apiKey = 'SUA_CHAVE_AQUI'; // ← Configure aqui
```

**Obtenha sua chave gratuita em**: [OpenWeatherMap API](https://openweathermap.org/api)

## 🔒 Segurança da API Key

### ⚠️ **MUITO IMPORTANTE - Segurança da API Key**

1. **Nunca faça commit da sua API key real no repositório**
2. **A API key no código está vazia (`''`) propositalmente**
3. **Para desenvolvimento local**: Coloque sua chave diretamente no código
4. **Para produção**: Use variáveis de ambiente ou arquivos de configuração

### 📝 **Boas Práticas de Segurança**
- ✅ Mantenha sua API key privada sempre
- ✅ Use `.env` files para diferentes ambientes (inclusos no .gitignore)
- ✅ Para Flutter Web/Desktop em produção, considere proxy de servidor
- ✅ Monitore o uso da sua API key no painel OpenWeatherMap

## 🤝 Contribuindo

1. Fork este repositório
2. Crie uma branch: `git checkout -b feature/sua-feature`
3. Commit suas mudanças: `git commit -m 'Adiciona nova feature'`
4. Push para a branch: `git push origin feature/sua-feature`
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a **MIT License**. 

## 🙏 Agradecimentos

- **OpenWeatherMap** - API meteorológica confiável
- **Google Fonts** - Tipografia moderna  
- **Flutter Team** - Framework excepcional

---

<div align="center">

**Weather Explorer** - *Sua previsão do tempo, reimaginada!* 

Desenvolvido com ❤️ por [RIGOandre](https://github.com/RIGOandre)

</div>
