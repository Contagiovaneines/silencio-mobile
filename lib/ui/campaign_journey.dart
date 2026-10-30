import 'dart:math' as math;

import 'package:flutter/material.dart';

class CampaignJourney extends StatefulWidget {
  const CampaignJourney({
    super.key,
    required this.completed,
    required this.hasSave,
    required this.localMap,
    required this.onPlay,
    required this.onBack,
    this.onPlayChapterTwo,
  });
  final bool completed, hasSave, localMap;
  final VoidCallback onPlay, onBack;
  final VoidCallback? onPlayChapterTwo;
  @override
  State<CampaignJourney> createState() => _CampaignJourneyState();
}

class _CampaignJourneyState extends State<CampaignJourney> {
  int selected = 0;
  String title(int i) => i == 0
      ? 'Um Dia Normal'
      : i == 1
      ? '02:00'
      : 'Capítulo ${i + 1}';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'JORNADA · SILÊNCIO',
              style: TextStyle(fontSize: 18, color: Color(0xffdfb477)),
            ),
          ),
          IconButton(
            tooltip: 'Voltar',
            onPressed: widget.onBack,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      const Text(
        'A história avança pelos seus acontecimentos. Somente a fase 01 está jogável.',
        style: TextStyle(color: Color(0xffa2cbb8), fontSize: 12),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: math.min(235, MediaQuery.sizeOf(context).height * .43),
        child: LayoutBuilder(
          builder: (context, bounds) => GridView.builder(
            itemCount: 12,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: bounds.maxWidth < 550 ? 4 : 6,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, i) => Semantics(
              selected: selected == i,
              child: OutlinedButton(
                onPressed: () => setState(() => selected = i),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  backgroundColor: selected == i
                      ? const Color(0xff304b49)
                      : const Color(0xff14272e),
                  side: BorderSide(
                    color: selected == i
                        ? const Color(0xffdfb477)
                        : const Color(0xff49605d),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == 0
                              ? widget.completed
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_checked
                              : i == 1 && widget.onPlayChapterTwo != null
                              ? Icons.play_circle_outline
                              : Icons.lock_outline,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text('${i + 1}'.padLeft(2, '0')),
                      ],
                    ),
                    Text(
                      title(i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${title(selected)} · ${selected == 0
            ? widget.completed
                  ? 'Concluído'
                  : 'Disponível'
            : selected == 1 && widget.onPlayChapterTwo != null
            ? 'Disponível'
            : 'Em produção'}',
        style: const TextStyle(color: Color(0xffe3e4d5), fontSize: 15),
      ),
      const SizedBox(height: 6),
      if (selected > 0 && !(selected == 1 && widget.onPlayChapterTwo != null))
        const Text(
          'Conclua o capítulo anterior para abrir 02:00. Os capítulos seguintes continuam em produção.',
          style: TextStyle(color: Color(0xffa2cbb8), fontSize: 12),
        ),
      if (selected == 0)
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: widget.onPlay,
            child: Text(
              widget.localMap
                  ? 'Voltar ao mapa local'
                  : widget.completed
                  ? 'Nova partida'
                  : widget.hasSave
                  ? 'Continuar fase 01'
                  : 'Começar fase 01',
            ),
          ),
        ),
      if (selected == 1 && widget.onPlayChapterTwo != null)
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: widget.onPlayChapterTwo,
            child: const Text('Jogar fase 02 · 02:00'),
          ),
        ),
    ],
  );
}
