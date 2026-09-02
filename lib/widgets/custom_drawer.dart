import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  final List<String> cities;
  final String currentCity;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String> onCityDeleted;
  final VoidCallback onAddCity;

  const CustomDrawer({
    super.key,
    required this.cities,
    required this.currentCity,
    required this.onCitySelected,
    required this.onCityDeleted,
    required this.onAddCity,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: AppTheme.drawer),
        // O Drawer não aplica SafeArea nos filhos: sem isso o botão de adicionar
        // fica sob a barra de gestos. O topo segue livre para o gradiente do
        // cabeçalho continuar subindo atrás da barra de status.
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(child: _buildCityList()),
              _buildAddCityButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      // Altura mínima em vez de fixa: com a fonte do sistema ampliada o
      // cabeçalho cresce em vez de estourar.
      constraints: const BoxConstraints(minHeight: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(gradient: AppTheme.drawerHeader),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.location_city,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cidades Salvas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecione ou gerencie suas cidades',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCityList() {
    if (cities.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma cidade salva',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione uma cidade para começar',
                style: TextStyle(
                  // 0.6 sobre o azul do menu fica com contraste baixo demais
                  // para texto secundário.
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        final isSelected = city == currentCity;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.3))
                : null,
          ),
          child: ListTile(
            selected: isSelected,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSelected ? Icons.location_on : Icons.location_city,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              city,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            subtitle: isSelected
                ? Text(
                    'Cidade atual',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: cities.length > 1
                ? IconButton(
                    // O tooltip também vira rótulo para o leitor de tela, que
                    // sem ele anuncia só "botão" em todas as linhas.
                    tooltip: 'Remover $city',
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[300],
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(context, city),
                  )
                : null,
            // Tocar na cidade já selecionada fecha o menu, que é o que o gesto
            // sugere; nas demais quem fecha é quem trata onCitySelected.
            onTap: isSelected
                ? () => Navigator.pop(context)
                : () => onCitySelected(city),
          ),
        );
      },
    );
  }

  Widget _buildAddCityButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onAddCity,
          icon: const Icon(Icons.add_location),
          label: const Text(
            'Adicionar Cidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[800],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String city) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover cidade'),
        content: Text('Deseja remover "$city" da lista de cidades salvas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCityDeleted(city);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
