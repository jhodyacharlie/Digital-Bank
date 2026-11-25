import 'package:flutter/material.dart';

import 'app_style.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.pin,
    required this.onDigit,
    required this.onDelete,
    this.leftButton,
  });

  final String pin;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? leftButton;

  Widget tombol(BuildContext context, String angka) {
    return SizedBox(
      width: 80,
      height: 64,
      child: TextButton(
        onPressed: () => onDigit(angka),
        child: Text(
          angka,
          style: TextStyle(fontSize: 28, color: context.teksUtama),
        ),
      ),
    );
  }

  Widget baris(BuildContext context, List<String> angka) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: angka.map((a) => tombol(context, a)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final terisi = i < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: terisi ? AppColors.biru : Colors.transparent,
                border: Border.all(color: AppColors.biru, width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        baris(context, ['1', '2', '3']),
        baris(context, ['4', '5', '6']),
        baris(context, ['7', '8', '9']),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 80,
              height: 64,
              child: leftButton ?? const SizedBox(),
            ),
            tombol(context, '0'),
            SizedBox(
              width: 80,
              height: 64,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.backspace_outlined,
                  color: AppColors.biru,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
