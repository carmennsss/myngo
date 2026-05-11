import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';
import '../../models/comunidad.dart';
import '../../services/servicio_comunidades.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class LateralDerecho extends StatelessWidget {
  const LateralDerecho({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFFF2D0BD).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFFF29C50).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF248EA6).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF248EA6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(tr('communitySuggestions'), style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder(
                future: ServicioComunidades().listarComunidadesPopulares(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF29C50))));

                  final sugeridas = snapshot.data?.datos?.take(4).toList() ?? [];
                  if (sugeridas.isEmpty) return Text(tr('communityExploreMore'), style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13));

                  return Column(
                    children: sugeridas.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18, 
                              backgroundColor: Colors.white, 
                              child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFC35E34), fontWeight: FontWeight.bold))
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('c/${c.nombre}', style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontSize: 14, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF248EA6), const Color(0xFF248EA6).withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF248EA6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(tr('communityHaveAPet'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(tr('communityHavePetDesc'), textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF248EA6),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(tr('communityCreateBtn'), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
