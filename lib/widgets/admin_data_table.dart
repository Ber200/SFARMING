import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AdminTableColumn {
  final String title;
  final double? width;
  final bool flex;
  final Alignment alignment;

  const AdminTableColumn({
    required this.title,
    this.width,
    this.flex = false,
    this.alignment = Alignment.centerLeft,
  });
}

class AdminDataTable extends StatelessWidget {
  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final Widget? emptyWidget;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 240,
        decoration: AppTheme.adminCardDecoration(),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.adminPrimary),
        ),
      );
    }

    if (rows.isEmpty) {
      return emptyWidget ??
          Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.adminCardDecoration(),
            child: const Center(
              child: Text(
                'No records found.',
                style: TextStyle(color: AppTheme.adminTextSecondary, fontSize: 13),
              ),
            ),
          );
    }

    return Container(
      decoration: AppTheme.adminCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            color: AppTheme.adminSurfaceSubtle,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: columns.map((col) {
                final child = Align(
                  alignment: col.alignment,
                  child: Text(
                    col.title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adminTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
                if (col.flex) {
                  return Expanded(child: child);
                } else if (col.width != null) {
                  return SizedBox(width: col.width, child: child);
                }
                return Expanded(child: child);
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppTheme.adminBorder),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.adminBorderLight),
            itemBuilder: (context, rowIndex) {
              final rowCells = rows[rowIndex];
              return Container(
                color: rowIndex.isEven ? Colors.white : const Color(0xFFFAFCFA),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: List.generate(columns.length, (colIndex) {
                    final col = columns[colIndex];
                    final cell = colIndex < rowCells.length ? rowCells[colIndex] : const SizedBox.shrink();
                    final alignedCell = Align(alignment: col.alignment, child: cell);

                    if (col.flex) {
                      return Expanded(child: alignedCell);
                    } else if (col.width != null) {
                      return SizedBox(width: col.width, child: alignedCell);
                    }
                    return Expanded(child: alignedCell);
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
