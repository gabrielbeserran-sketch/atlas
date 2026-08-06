import 'package:flutter/material.dart';
import '../../data/services/atlas_integration_repository.dart';
import '../../domain/models/atlas_integration_connection.dart';

class AtlasIntegrationCenterScreen extends StatefulWidget {
  const AtlasIntegrationCenterScreen({super.key});
  @override State<AtlasIntegrationCenterScreen> createState()=>_AtlasIntegrationCenterScreenState();
}

class _AtlasIntegrationCenterScreenState extends State<AtlasIntegrationCenterScreen> {
  final _repository = AtlasIntegrationRepository();
  List<AtlasIntegrationConnection> _items = const [];
  bool _loading = true;

  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final items=await _repository.load(); if(!mounted)return; setState((){_items=items;_loading=false;});}
  Future<void> _save()=>_repository.save(_items);

  String _type(AtlasIntegrationType value)=>switch(value){AtlasIntegrationType.csv=>'CSV',AtlasIntegrationType.excel=>'Excel',AtlasIntegrationType.scale=>'Balança',AtlasIntegrationType.rfid=>'RFID',AtlasIntegrationType.weather=>'Meteorologia',AtlasIntegrationType.financial=>'Financeiro',AtlasIntegrationType.erp=>'ERP rural',AtlasIntegrationType.api=>'API'};
  String _status(AtlasConnectionStatus value)=>switch(value){AtlasConnectionStatus.connected=>'Conectada',AtlasConnectionStatus.attention=>'Atenção',AtlasConnectionStatus.disconnected=>'Desconectada'};
  Color _color(AtlasConnectionStatus value)=>switch(value){AtlasConnectionStatus.connected=>Colors.green,AtlasConnectionStatus.attention=>Colors.orange,AtlasConnectionStatus.disconnected=>Colors.grey};
  String _date(DateTime? value){if(value==null)return 'Nunca sincronizada';return '${value.day.toString().padLeft(2,'0')}/${value.month.toString().padLeft(2,'0')}/${value.year} ${value.hour.toString().padLeft(2,'0')}:${value.minute.toString().padLeft(2,'0')}';}

  Future<void> _sync(AtlasIntegrationConnection item) async {
    final updated=item.copyWith(status:AtlasConnectionStatus.connected,lastSyncAt:DateTime.now(),recordsProcessed:item.recordsProcessed+12);
    setState(()=>_items=_items.map((e)=>e.id==item.id?updated:e).toList()); await _save();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${item.name} sincronizada com sucesso.')));
  }

  Future<void> _toggle(AtlasIntegrationConnection item,bool value) async {setState(()=>_items=_items.map((e)=>e.id==item.id?item.copyWith(autoSync:value):e).toList());await _save();}

  @override Widget build(BuildContext context){
    final connected=_items.where((e)=>e.status==AtlasConnectionStatus.connected).length;
    final automatic=_items.where((e)=>e.autoSync).length;
    final records=_items.fold<int>(0,(sum,e)=>sum+e.recordsProcessed);
    return Scaffold(
      backgroundColor:const Color(0xFFF5F6F8),
      appBar:AppBar(title:const Text('Central de Integrações'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh),tooltip:'Atualizar')]),
      body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(20),children:[
        Wrap(spacing:12,runSpacing:12,children:[_Metric('Conexões','${_items.length}',Icons.hub_outlined),_Metric('Conectadas','$connected',Icons.link_outlined),_Metric('Automáticas','$automatic',Icons.sync_outlined),_Metric('Registros','$records',Icons.data_usage_outlined)]),
        const SizedBox(height:24),
        const Text('Conexões e fontes de dados',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        const Text('Prepare o Atlas para importar, exportar e sincronizar dados com planilhas, equipamentos e serviços externos.',style:TextStyle(color:Colors.black54)),
        const SizedBox(height:14),
        ..._items.map((item){final color=_color(item.status);return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[CircleAvatar(backgroundColor:color.withValues(alpha:.12),child:Icon(Icons.cable_outlined,color:color)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.name,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),Text('${_type(item.type)} • ${_status(item.status)}',style:TextStyle(color:color,fontWeight:FontWeight.w600))])),FilledButton.icon(onPressed:()=>_sync(item),icon:const Icon(Icons.sync),label:const Text('Sincronizar'))]),
          const SizedBox(height:12),Text('Última sincronização: ${_date(item.lastSyncAt)}'),Text('${item.recordsProcessed} registros processados',style:const TextStyle(color:Colors.black54)),if(item.notes.isNotEmpty)...[const SizedBox(height:6),Text(item.notes,style:const TextStyle(color:Colors.black54))],
          const Divider(height:24),SwitchListTile(contentPadding:EdgeInsets.zero,value:item.autoSync,onChanged:(value)=>_toggle(item,value),title:const Text('Sincronização automática'),subtitle:const Text('Executar quando uma fonte compatível estiver disponível.'))
        ])));}),
        const SizedBox(height:20),
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Importação e exportação',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('A estrutura está preparada para receber os seletores reais de arquivos e os conectores externos na próxima etapa.'),const SizedBox(height:14),Wrap(spacing:10,runSpacing:10,children:[OutlinedButton.icon(onPressed:()=>_message('Importação CSV preparada.'),icon:const Icon(Icons.upload_file),label:const Text('Importar CSV')),OutlinedButton.icon(onPressed:()=>_message('Importação Excel preparada.'),icon:const Icon(Icons.table_view_outlined),label:const Text('Importar Excel')),OutlinedButton.icon(onPressed:()=>_message('Exportação preparada.'),icon:const Icon(Icons.download_outlined),label:const Text('Exportar dados'))])]))),
        const SizedBox(height:80),
      ])));
  }
  void _message(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));
}

class _Metric extends StatelessWidget {const _Metric(this.label,this.value,this.icon);final String label,value;final IconData icon;@override Widget build(BuildContext context)=>SizedBox(width:190,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const SizedBox(height:10),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(label,style:const TextStyle(color:Colors.black54))]))));}
