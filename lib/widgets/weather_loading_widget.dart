import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WeatherLoadingWidget extends StatelessWidget {
  const WeatherLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Temperature Loading
          _buildShimmerContainer(
            width: 200,
            height: 80,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          
          // Description Loading
          _buildShimmerContainer(
            width: 150,
            height: 24,
            borderRadius: 12,
          ),
          const SizedBox(height: 24),
          
          // Weather Icon Loading
          _buildShimmerContainer(
            width: 100,
            height: 100,
            borderRadius: 50,
          ),
          const SizedBox(height: 24),
          
          // Location Loading
          _buildShimmerContainer(
            width: 180,
            height: 20,
            borderRadius: 10,
          ),
          const SizedBox(height: 32),
          
          // Forecast Container Loading
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildShimmerContainer(
                  width: 200,
                  height: 20,
                  borderRadius: 10,
                ),
                const SizedBox(height: 16),
                ...List.generate(5, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerContainer(width: 60, height: 16, borderRadius: 8),
                      _buildShimmerContainer(width: 40, height: 16, borderRadius: 8),
                      _buildShimmerContainer(width: 40, height: 16, borderRadius: 8),
                      _buildShimmerContainer(width: 40, height: 16, borderRadius: 8),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Info Cards Loading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) => Column(
              children: [
                _buildShimmerContainer(width: 60, height: 20, borderRadius: 10),
                const SizedBox(height: 8),
                _buildShimmerContainer(width: 80, height: 16, borderRadius: 8),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}