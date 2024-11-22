import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solace/themes/colors.dart';

class ChartTesting extends StatelessWidget {
  final List<double> vitalArray;
  final List<DateTime> timestampArray;

  // Gradient colors for the line and the area below the line
  static List<Color> gradientColors = [
    AppColors.neon,
    AppColors.purple,
  ];

  const ChartTesting({
    super.key,
    required this.vitalArray,
    required this.timestampArray,
  });

  // Function to calculate left titles: Highest, Rounded Average of High and Low, and Lowest values
  List<int> calculateLeftTitles(List<double> data) {
    if (data.isEmpty) return [0, 0, 0];

    double maxValue = data.reduce((a, b) => a > b ? a : b); // Highest value
    double minValue = data.reduce((a, b) => a < b ? a : b); // Lowest value
    double avgValue =
        (maxValue + minValue) / 2; // Average of highest and lowest
    int roundedAvgValue = avgValue.round(); // Rounded average

    return [
      maxValue.toInt(), // Highest value
      roundedAvgValue, // Rounded average
      minValue.toInt(), // Lowest value
    ];
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Vital Array: $vitalArray");
    debugPrint("Timestamp Array: $timestampArray");

    if (vitalArray.isEmpty || timestampArray.isEmpty) {
      return const Center(
        child: Text('No data available for chart'),
      );
    }

    // Calculate left titles: Highest, Rounded Average, and Lowest
    final leftTitles = calculateLeftTitles(vitalArray);

    // Process timestamps for the x-axis (e.g., only showing dates like "15")
    final formattedTimestamps =
        timestampArray.map((timestamp) => timestamp.day.toString()).toList();

    // Calculate the interval for left titles (3 values: max, avg, min)
    double interval =
        (leftTitles[0] - leftTitles[2]) / 3.0; // 3 intervals for 3 labels

// Ensure that the interval is not zero
    if (interval == 0) {
      interval = 1; // Default to 1 if interval is zero
    }

    // Add some margin/padding to ensure the line fits within the chart area
    double minY = leftTitles[2].toDouble() - 5; // Add padding below min
    double maxY = leftTitles[0].toDouble() + 5; // Add padding above max

    return SizedBox(
      height: 200, // Set the height of the graph
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(touchedSpot.y.toString(), textStyle);
                }).toList();
              },
              getTooltipColor: (touchedSpot) => AppColors.blackTransparent,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < formattedTimestamps.length) {
                    return Text(
                      formattedTimestamps[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                interval: 1, // One grid line for each timestamp
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final intValue = value.toInt();
                  // Display titles only for the three calculated values: max, avg, min
                  if (intValue == leftTitles[0] ||
                      intValue == leftTitles[1] ||
                      intValue == leftTitles[2]) {
                    return Text(
                      intValue.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                interval: interval, // Adjust interval to match 3 grid lines
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Remove top titles
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Remove right titles
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(vitalArray.length, (index) {
                return FlSpot(index.toDouble(), vitalArray[index]);
              }),
              isCurved: true,
              preventCurveOverShooting: true,
              isStrokeCapRound: true,
              barWidth: 4,
              dotData: FlDotData(show: true),
              // Apply gradient to the line itself
              gradient: LinearGradient(
                colors: gradientColors,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                ),
              ),
            ),
          ],

          gridData: FlGridData(
            show: true,
            horizontalInterval:
                (maxY - minY) / 3.0, // More fine-grained intervals
            verticalInterval: 1, // One vertical grid for each timestamp
          ),
          borderData: FlBorderData(show: true),
          minY: leftTitles[2]
              .toDouble(), // Set minY to the lowest value (min) with some padding
          baselineY: leftTitles[1].toDouble(),
          maxY: leftTitles[0]
              .toDouble(), // Set maxY to the highest value (max) with some padding
          minX: 0,
          maxX: formattedTimestamps.length.toDouble() - 1,
        ),
      ),
    );
  }
}
