import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AnalyticsGraphPopup extends StatelessWidget {
  final String title;
  final String chatResponse;
  final Map<String, dynamic> data;

  const AnalyticsGraphPopup({
    super.key,
    required this.title,
    required this.chatResponse,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.heading3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildGraph()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph() {
    // Determine graph type based on data and chat response
    if (_isTopProductsAnalysis()) {
      return _buildBarChart();
    } else if (_isSalesTrendAnalysis()) {
      return _buildLineChart();
    } else if (_isCategoryAnalysis()) {
      return _buildPieChart();
    } else {
      return _buildDefaultChart();
    }
  }

  bool _isTopProductsAnalysis() {
    final response = chatResponse.toLowerCase();
    return response.contains('top') &&
        (response.contains('product') ||
            response.contains('selling') ||
            response.contains('best'));
  }

  bool _isSalesTrendAnalysis() {
    final response = chatResponse.toLowerCase();
    return response.contains('trend') ||
        response.contains('over time') ||
        response.contains('period') ||
        response.contains('recent');
  }

  bool _isCategoryAnalysis() {
    final response = chatResponse.toLowerCase();
    return response.contains('category') ||
        response.contains('by category') ||
        response.contains('grouped');
  }

  Widget _buildBarChart() {
    final topProducts = data['top_selling_products'] as List? ?? [];

    if (topProducts.isEmpty) {
      return _buildNoDataMessage();
    }

    final chartData = topProducts.take(5).map((product) {
      return BarChartGroupData(
        x: topProducts.indexOf(product),
        barRods: [
          BarChartRodData(
            toY: (product['total_sold_quantity'] as num).toDouble(),
            color: AppTheme.primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Text('Top Selling Products', style: AppTheme.heading4),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartData.isNotEmpty
                  ? chartData
                            .map((d) => d.barRods.first.toY)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2
                  : 100,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < topProducts.length) {
                        final product = topProducts[value.toInt()];
                        final name = product['product_name'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            name.split(' ').take(2).join(' '),
                            style: AppTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: chartData,
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final recentTransactions = data['recent_transactions'] as List? ?? [];

    if (recentTransactions.isEmpty) {
      return _buildNoDataMessage();
    }

    final chartData = recentTransactions.take(10).map((transaction) {
      return FlSpot(
        recentTransactions.indexOf(transaction).toDouble(),
        (transaction['absolute_quantity'] as num).toDouble(),
      );
    }).toList();

    return Column(
      children: [
        Text('Sales Trend (Recent Transactions)', style: AppTheme.heading4),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTheme.bodySmall,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTheme.bodySmall,
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d)),
              ),
              minX: 0,
              maxX: (chartData.length - 1).toDouble(),
              minY: 0,
              maxY: chartData.isNotEmpty
                  ? chartData
                            .map((spot) => spot.y)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2
                  : 10,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.5),
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.primaryColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final categories = data['categories'] as List? ?? [];

    if (categories.isEmpty) {
      return _buildNoDataMessage();
    }

    final chartData = categories.map((category) {
      return PieChartSectionData(
        color: _getRandomColor(categories.indexOf(category)),
        value: (category['product_count'] as num).toDouble(),
        title: '${category['product_count']}',
        radius: 60,
        titleStyle: AppTheme.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text('Products by Category', style: AppTheme.heading4),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: chartData,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getRandomColor(
                                categories.indexOf(category),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category['category_name'] as String,
                              style: AppTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultChart() {
    return Column(
      children: [
        Text('Analytics Overview', style: AppTheme.heading4),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Analytics data available',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check the data for visualization options',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No data available for visualization',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getRandomColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      AppTheme.infoColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
