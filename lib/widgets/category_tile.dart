// lib/widgets/category_tile.dart
import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;

  const CategoryTile({
    required this.letter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}