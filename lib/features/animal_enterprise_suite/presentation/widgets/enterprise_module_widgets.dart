import 'package:flutter/material.dart';

class EnterpriseModuleHeader extends StatelessWidget {
  const EnterpriseModuleHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
      ),
      child: Row(children: [
        Container(width: 64,height:64,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.16),borderRadius:BorderRadius.circular(18)),child:Icon(icon,color:Colors.white,size:34)),
        const SizedBox(width:18),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Colors.white70))])),
      ]),
    ),
  );
}

class EnterpriseMetricCard extends StatelessWidget {
  const EnterpriseMetricCard({required this.title,required this.value,required this.subtitle,required this.icon,this.warning=false,super.key});
  final String title,value,subtitle; final IconData icon; final bool warning;
  @override Widget build(BuildContext context){final c=warning?Colors.orange.shade800:const Color(0xFF1B5E20);return SizedBox(width:340,child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[CircleAvatar(backgroundColor:c.withValues(alpha:.10),child:Icon(icon,color:c)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.black54)),const SizedBox(height:3),Text(value,style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:warning?c:null)),const SizedBox(height:3),Text(subtitle,style:const TextStyle(fontSize:12,color:Colors.black54))]))]))));}
}

class EnterpriseInsightCard extends StatelessWidget {
  const EnterpriseInsightCard({required this.title,required this.items,this.icon=Icons.psychology_alt_outlined,super.key});
  final String title; final List<String> items; final IconData icon;
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:const Color(0xFF1B5E20)),const SizedBox(width:10),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold))]),const SizedBox(height:14),...items.map((e)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Padding(padding:EdgeInsets.only(top:3),child:Icon(Icons.check_circle_outline,size:17,color:Color(0xFF1B5E20))),const SizedBox(width:9),Expanded(child:Text(e))]))) ])));
}

class EnterpriseSectionTitle extends StatelessWidget {
  const EnterpriseSectionTitle(this.title,this.subtitle,{super.key}); final String title,subtitle;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.black54))]);
}

String enterpriseDate(DateTime d){final day=d.day.toString().padLeft(2,'0');final month=d.month.toString().padLeft(2,'0');return '$day/$month/${d.year}';}
DateTime parseEnterpriseDate(String value){final iso=DateTime.tryParse(value);if(iso!=null)return iso;final p=value.split('/');if(p.length==3)return DateTime(int.tryParse(p[2])??1900,int.tryParse(p[1])??1,int.tryParse(p[0])??1);return DateTime(1900);}
