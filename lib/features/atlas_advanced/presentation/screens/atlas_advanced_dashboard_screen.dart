import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_advanced/data/services/atlas_advanced_service.dart';
import 'package:projeto_atlas/features/atlas_advanced/domain/models/atlas_advanced_data.dart';

class AtlasAdvancedDashboardScreen extends StatefulWidget {
  const AtlasAdvancedDashboardScreen({super.key,required this.farmId,required this.farmName});
  final String farmId,farmName;
  @override State<AtlasAdvancedDashboardScreen> createState()=>_State();
}
class _State extends State<AtlasAdvancedDashboardScreen>{
  final _service=AtlasAdvancedService(); Future<AtlasAdvancedDashboardData>? _future;
  @override void initState(){super.initState();_reload();}
  void _reload()=>setState(()=>_future=_service.dashboard(widget.farmId));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Atlas Avançado • ${widget.farmName}'),actions:[IconButton(onPressed:_reload,icon:const Icon(Icons.refresh))]),body:FutureBuilder<AtlasAdvancedDashboardData>(future:_future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Falha ao carregar: ${s.error}'));final d=s.data!;return RefreshIndicator(onRefresh:()async=>_reload(),child:ListView(padding:const EdgeInsets.all(16),children:[Wrap(spacing:12,runSpacing:12,children:[_card('IA',d.aiForecasts,Icons.psychology),_card('Mapas',d.geoAssets,Icons.map),_card('Pastagens',d.pastureRecords,Icons.grass),_card('Agricultura',d.agricultureRecords,Icons.agriculture),_card('Genética',d.geneticProfiles,Icons.biotech)]),const SizedBox(height:20),Text('Blocos implementados',style:Theme.of(context).textTheme.titleLarge),...d.implementedBlocks.map((x)=>ListTile(leading:const Icon(Icons.check_circle_outline),title:Text(x),subtitle:const Text('Integrado ao backend oficial da fazenda.')))]));}));
  Widget _card(String title,int value,IconData icon)=>SizedBox(width:190,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),Text('$value registros',style:Theme.of(context).textTheme.titleMedium)]))));
}
