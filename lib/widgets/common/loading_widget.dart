import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConfig.defaultPadding),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingWidget(
              message: loadingMessage ?? 'Loading...',
              size: 50,
            ),
          ),
      ],
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    // Note: This is a simplified shimmer effect
    // For a more advanced shimmer, consider using the shimmer package
    return Opacity(
      opacity: 0.3,
      child: child,
    );
  }
}

class LoadingCard extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.cardBorderRadius),
      ),
      child: ShimmerLoading(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.cardBorderRadius),
          ),
        ),
      ),
    );
  }
}

class LoadingProductCard extends StatelessWidget {
  final double? width;
  final double? height;

  const LoadingProductCard({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: LoadingCard(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConfig.cardBorderRadius),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingCard(
                    height: 16,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  LoadingCard(
                    height: 12,
                    width: 60,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: LoadingCard(
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LoadingCard(
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingProductGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const LoadingProductGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppConfig.defaultPadding,
        mainAxisSpacing: AppConfig.defaultPadding,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const LoadingProductCard();
      },
    );
  }
}

class LoadingCategoryCard extends StatelessWidget {
  final double? width;
  final double? height;

  const LoadingCategoryCard({
    super.key,
    this.width = 100,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: AppConfig.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingCard(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(30),
          ),
          const SizedBox(height: 8),
          LoadingCard(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}

class LoadingCategoryList extends StatelessWidget {
  final int itemCount;

  const LoadingCategoryList({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const LoadingCategoryCard();
        },
      ),
    );
  }
}