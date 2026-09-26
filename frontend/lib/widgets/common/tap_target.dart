import 'package:flutter/material.dart';

/// ห่อ widget ที่กดได้ให้มีพื้นที่กดอย่างน้อย 48x48 (ขั้นต่ำด้าน accessibility) โดยขนาดที่มองเห็นไม่เปลี่ยน
/// และประกาศเป็นปุ่มให้ screen reader อ่าน — ใช้แทน GestureDetector ตรง ๆ กับลิงก์ข้อความหรือไอคอนเล็ก ๆ
///
/// [label] จำเป็นเมื่อ [child] ไม่มีข้อความ (เช่น ไอคอนล้วน) ถ้า child เป็น Text อยู่แล้วไม่ต้องใส่
/// ถ้า [child] มี InkWell ของตัวเองอยู่แล้ว การกดบนตัว child จะไปที่ InkWell นั้น ส่วนขอบที่ขยายออกมาจะเรียก [onTap] ตัวนี้แทน
class TapTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;
  final bool? selected;
  final Widget child;

  const TapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinInteractiveDimension,
              minHeight: kMinInteractiveDimension,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
