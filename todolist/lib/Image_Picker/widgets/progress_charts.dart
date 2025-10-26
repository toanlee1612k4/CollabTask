import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressPieChart extends StatelessWidget {
  final int done;
  final int todo;

  const ProgressPieChart({super.key, required this.done, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Tỉ lệ hoàn thành', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: done.toDouble(),
                  title: '$done',
                  color: Colors.green,
                  radius: 50,
                ),
                PieChartSectionData(
                  value: todo.toDouble(),
                  title: '$todo',
                  color: Colors.orange,
                  radius: 40,
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendItem(color: Colors.green, text: "Hoàn thành"),
            SizedBox(width: 16),
            _LegendItem(color: Colors.orange, text: "Chưa xong"),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
