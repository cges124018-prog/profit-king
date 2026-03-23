import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const FlutterLayoutVisualizerApp());
}

class FlutterLayoutVisualizerApp extends StatelessWidget {
  const FlutterLayoutVisualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Layout Deep-Dive Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0E12),
        canvasColor: const Color(0xFF11141A),
        cardColor: const Color(0xFF1A1D24),
        dividerColor: Colors.white10,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF1A1D24),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ==========================================
// 1. Core Visual Layout Node Model
// ==========================================

enum LayoutNodeType { container, row, column, text, expanded, padding, align }

class LayoutNode {
  final String id;
  final String label;
  final LayoutNodeType type;
  final Map<String, dynamic> properties;
  final List<LayoutNode> children;

  // Computed visual properties for drawing
  Size size = Size.zero;
  Offset position = Offset.zero;
  BoxConstraints inputConstraints = const BoxConstraints();
  
  // Custom paint colors
  final Color baseColor;

  LayoutNode({
    required this.id,
    required this.label,
    required this.type,
    this.properties = const {},
    this.children = const [],
    this.baseColor = const Color(0xFF38BDF8),
  });

  Color get color {
    switch (type) {
      case LayoutNodeType.container: return const Color(0xFF0284C7);
      case LayoutNodeType.expanded: return const Color(0xFF0EA5E9);
      case LayoutNodeType.row: return const Color(0xFFF59E0B);
      case LayoutNodeType.column: return const Color(0xFF10B981);
      case LayoutNodeType.padding: return const Color(0xFF8B5CF6);
      case LayoutNodeType.align: return const Color(0xFFEC4899);
      case LayoutNodeType.text: return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (type) {
      case LayoutNodeType.container: return Icons.check_box_outline_blank;
      case LayoutNodeType.expanded: return Icons.expand;
      case LayoutNodeType.row: return Icons.view_week;
      case LayoutNodeType.column: return Icons.view_headline;
      case LayoutNodeType.padding: return Icons.space_bar;
      case LayoutNodeType.align: return Icons.align_horizontal_center;
      case LayoutNodeType.text: return Icons.text_fields;
    }
  }
}

// ==========================================
// 2. Custom Layout Management & Layout Simulation
// ==========================================

class MockLayoutEngine {
  static void computeLayout(LayoutNode node, BoxConstraints constraints, {Offset origin = Offset.zero}) {
    node.inputConstraints = constraints;
    node.position = origin;

    switch (node.type) {
      case LayoutNodeType.container:
        _layoutContainer(node, constraints, origin);
        break;
      case LayoutNodeType.padding:
        _layoutPadding(node, constraints, origin);
        break;
      case LayoutNodeType.row:
        _layoutRow(node, constraints, origin);
        break;
      case LayoutNodeType.column:
        _layoutColumn(node, constraints, origin);
        break;
      case LayoutNodeType.expanded:
        _layoutExpanded(node, constraints, origin);
        break;
      case LayoutNodeType.text:
        _layoutText(node, constraints, origin);
        break;
      case LayoutNodeType.align:
        _layoutAlign(node, constraints, origin);
        break;
    }
  }

  static void _layoutContainer(LayoutNode node, BoxConstraints constraints, Offset origin) {
    double width = node.properties['width'] ?? constraints.maxWidth;
    double height = node.properties['height'] ?? constraints.maxHeight;

    // Constrain by parent
    width = width.clamp(constraints.minWidth, constraints.maxWidth);
    height = height.clamp(constraints.minHeight, constraints.maxHeight);

    node.size = Size(width, height);

    if (node.children.isNotEmpty) {
      BoxConstraints childConstraints = BoxConstraints(
        minWidth: 0,
        maxWidth: width,
        minHeight: 0,
        maxHeight: height,
      );
      computeLayout(node.children.first, childConstraints, origin: origin);
    }
  }

  static void _layoutPadding(LayoutNode node, BoxConstraints constraints, Offset origin) {
    double pad = node.properties['padding'] ?? 16.0;
    BoxConstraints childConstraint = constraints.deflate(EdgeInsets.all(pad));
    
    if (node.children.isNotEmpty) {
      computeLayout(node.children.first, childConstraint, origin: origin + Offset(pad, pad));
      node.size = Size(
        node.children.first.size.width + (pad * 2),
        node.children.first.size.height + (pad * 2),
      );
    } else {
      node.size = Size(pad * 2, pad * 2);
    }
  }

  static void _layoutText(LayoutNode node, BoxConstraints constraints, Offset origin) {
    String content = node.properties['content'] ?? node.label;
    double fontSize = node.properties['fontSize'] ?? 14.0;
    
    // Rough estimation of text size
    double textWidth = content.length * fontSize * 0.6;
    double textHeight = fontSize * 1.2;

    node.size = Size(
      textWidth.clamp(constraints.minWidth, constraints.maxWidth),
      textHeight.clamp(constraints.minHeight, constraints.maxHeight),
    );
  }

  static void _layoutRow(LayoutNode node, BoxConstraints constraints, Offset origin) {
    double currentX = origin.dx;
    double maxHeight = 0;
    double consumedWidth = 0;
    int expandedCount = 0;

    // 1st pass: Layout non-flexible children
    for (var child in node.children) {
      if (child.type != LayoutNodeType.expanded) {
        computeLayout(child, BoxConstraints(maxWidth: constraints.maxWidth - consumedWidth, maxHeight: constraints.maxHeight), origin: Offset(currentX, origin.dy));
        consumedWidth += child.size.width;
        maxHeight = math.max(maxHeight, child.size.height);
      } else {
        expandedCount++;
      }
    }

    // 2nd pass: Layout expanded children
    if (expandedCount > 0) {
      double remainingWidth = math.max(0.0, constraints.maxWidth - consumedWidth);
      double share = remainingWidth / expandedCount;

      for (var child in node.children) {
        if (child.type == LayoutNodeType.expanded) {
          computeLayout(child, BoxConstraints.tightFor(width: share, height: constraints.maxHeight), origin: Offset(currentX, origin.dy));
          maxHeight = math.max(maxHeight, child.size.height);
        }
      }
    }

    // Position children
    double xOffset = origin.dx;
    for (var child in node.children) {
      child.position = Offset(xOffset, origin.dy);
      xOffset += child.size.width;
    }

    node.size = Size(constraints.maxWidth, maxHeight.clamp(constraints.minHeight, constraints.maxHeight));
  }

  static void _layoutColumn(LayoutNode node, BoxConstraints constraints, Offset origin) {
    double currentY = origin.dy;
    double maxWidth = 0;
    double consumedHeight = 0;
    int expandedCount = 0;

    // 1st pass
    for (var child in node.children) {
      if (child.type != LayoutNodeType.expanded) {
        computeLayout(child, BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight - consumedHeight), origin: Offset(origin.dx, currentY));
        consumedHeight += child.size.height;
        maxWidth = math.max(maxWidth, child.size.width);
      } else {
        expandedCount++;
      }
    }

    // 2nd pass
    if (expandedCount > 0) {
      double remainingHeight = math.max(0.0, constraints.maxHeight - consumedHeight);
      double share = remainingHeight / expandedCount;

      for (var child in node.children) {
        if (child.type == LayoutNodeType.expanded) {
          computeLayout(child, BoxConstraints.tightFor(width: constraints.maxWidth, height: share), origin: Offset(origin.dx, currentY));
          maxWidth = math.max(maxWidth, child.size.width);
        }
      }
    }

    // Position
    double yOffset = origin.dy;
    for (var child in node.children) {
      child.position = Offset(origin.dx, yOffset);
      yOffset += child.size.height;
    }

    node.size = Size(maxWidth.clamp(constraints.minWidth, constraints.maxWidth), constraints.maxHeight);
  }

  static void _layoutExpanded(LayoutNode node, BoxConstraints constraints, Offset origin) {
    node.size = Size(constraints.maxWidth, constraints.maxHeight);
    if (node.children.isNotEmpty) {
      computeLayout(node.children.first, constraints, origin: origin);
    }
  }

  static void _layoutAlign(LayoutNode node, BoxConstraints constraints, Offset origin) {
    node.size = Size(constraints.maxWidth, constraints.maxHeight);
    if (node.children.isNotEmpty) {
      LayoutNode child = node.children.first;
      computeLayout(child, BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight), origin: origin);

      // Simple implementation of alignment: center
      double offsetX = (node.size.width - child.size.width) / 2;
      double offsetY = (node.size.height - child.size.height) / 2;
      child.position = origin + Offset(offsetX, offsetY);
    }
  }
}

// ==========================================
// 3. Demo Data Sets
// ==========================================

class DemoLayouts {
  static LayoutNode basicContainer() {
    return LayoutNode(
      id: "1", label: "Container (Box)", type: LayoutNodeType.container,
      properties: {"width": 300.0, "height": 300.0},
      children: [
        LayoutNode(
          id: "2", label: "Padding [16.0]", type: LayoutNodeType.padding,
          properties: {"padding": 16.0},
          children: [
            LayoutNode(
              id: "3", label: "Inner Container", type: LayoutNodeType.container,
              properties: {"width": 150.0, "height": 100.0},
              children: [
                LayoutNode(id: "4", label: "Text", type: LayoutNodeType.text, properties: {"content": "Hello World!", "fontSize": 16.0})
              ]
            )
          ]
        )
      ]
    );
  }

  static LayoutNode flexSample() {
    return LayoutNode(
      id: "20", label: "Column", type: LayoutNodeType.column,
      children: [
        LayoutNode(id: "21", label: "Nav Bar", type: LayoutNodeType.container, properties: {"height": 50.0}),
        LayoutNode(
          id: "22", label: "Expanded Row", type: LayoutNodeType.expanded,
          children: [
            LayoutNode(id: "23", label: "Row", type: LayoutNodeType.row, children: [
              LayoutNode(id: "24", label: "Sidebar", type: LayoutNodeType.container, properties: {"width": 100.0}),
              LayoutNode(
                id: "25", label: "Expanded Main", type: LayoutNodeType.expanded,
                children: [
                   LayoutNode(
                     id: "26", label: "Container", type: LayoutNodeType.container,
                     children: [
                        LayoutNode(id: "27", label: "Center Align", type: LayoutNodeType.align, children: [
                          LayoutNode(id: "28", label: "Text", type: LayoutNodeType.text, properties: {"content": "Center Dashboard", "fontSize": 20.0})
                        ])
                     ]
                   )
                ]
              )
            ])
          ]
        ),
        LayoutNode(id: "29", label: "Footer", type: LayoutNodeType.container, properties: {"height": 30.0}),
      ]
    );
  }
}


// ==========================================
// 4. Main Views / Screen Layouts
// ==========================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LayoutNode currentTree = DemoLayouts.basicContainer();
  LayoutNode? selectedNode;
  double viewScale = 1.0;
  double timelineProgress = 1.0; // Slider to show layout process steps

  @override
  void initState() {
    super.initState();
    _recalculateLayout();
  }

  void _recalculateLayout() {
    MockLayoutEngine.computeLayout(currentTree, const BoxConstraints(maxWidth: 600, maxHeight: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar: Nodes / Controls
          Container(
            width: 280,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.dashboard_customize, color: Color(0xFF38BDF8), size: 24),
                      SizedBox(width: 12),
                      Text("Structure Tree", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                // Presets
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              currentTree = DemoLayouts.basicContainer();
                              _recalculateLayout();
                              selectedNode = null;
                            });
                          },
                          child: const Text("Container Box"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              currentTree = DemoLayouts.flexSample();
                              _recalculateLayout();
                              selectedNode = null;
                            });
                          },
                          child: const Text("Flex Grid"),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: _buildTreeNode(currentTree),
                  ),
                ),
              ],
            ),
          ),
          
          // Center: The Artboard Canvas
          Expanded(
            child: Column(
              children: [
                // Top control bar
                _buildCanvasToolbar(),
                // Canvas Area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: GridPainter())),
                          Center(
                            child: InteractiveViewer(
                              boundaryMargin: const EdgeInsets.all(300),
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Transform.scale(
                                scale: viewScale,
                                child: SizedBox(
                                  width: 600,
                                  height: 500,
                                  child: Stack(
                                    children: _buildVisualNodes(currentTree),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Inspector panel
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(left: BorderSide(color: Colors.white10)),
            ),
            child: selectedNode == null
                ? const Center(child: Text("Select a Node for Info", style: TextStyle(color: Colors.grey)))
                : InspectorPanel(node: selectedNode!),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasToolbar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF14171D),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text("Visual Stage:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Slider(
              value: timelineProgress,
              onChanged: (v) {
                setState(() => timelineProgress = v);
              },
            ),
          ),
          const SizedBox(width: 10),
          Text("${(timelineProgress * 100).toInt()}%", style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(width: 24),
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => setState(() => viewScale += 0.1)),
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => setState(() => viewScale = math.max(0.3, viewScale - 0.1))),
          IconButton(icon: const Icon(Icons.center_focus_strong), onPressed: () => setState(() => viewScale = 1.0)),
        ],
      ),
    );
  }

  Widget _buildTreeNode(LayoutNode node) {
    bool isSelected = selectedNode?.id == node.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedNode = node),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? node.color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSelected ? node.color : Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(node.icon, size: 16, color: node.color),
                const SizedBox(width: 8),
                Text(node.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
        if (node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: node.children.map((child) => _buildTreeNode(child)).toList(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildVisualNodes(LayoutNode node) {
    List<Widget> items = [];

    // Simple reveal animation based on pipeline steps
    // Step 0-33%: Constraint arrows down
    // Step 33-66%: Size calculations
    // Step 66-100%: Positions placed

    items.add(
      Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: GestureDetector(
          onTap: () => setState(() => selectedNode = node),
          child: Container(
            width: node.size.width,
            height: node.size.height,
            decoration: BoxDecoration(
              color: node.color.withValues(alpha: 0.1),
              border: Border.all(
                color: selectedNode?.id == node.id ? Colors.white : node.color.withValues(alpha: 0.8),
                width: selectedNode?.id == node.id ? 2.0 : 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 4, top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: node.color, borderRadius: BorderRadius.circular(3)),
                    child: Text(
                      node.label.length > 10 ? node.label.substring(0, 10) : node.label,
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (var child in node.children) {
      items.addAll(_buildVisualNodes(child));
    }

    return items;
  }
}

// Grid painter background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Right Inspector
class InspectorPanel extends StatelessWidget {
  final LayoutNode node;
  const InspectorPanel({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: node.color.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(node.icon, color: node.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(node.type.name.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection("Calculated Layout"),
              _buildValue("Width", "${node.size.width.toStringAsFixed(1)} px"),
              _buildValue("Height", "${node.size.height.toStringAsFixed(1)} px"),
              _buildValue("Position Offset", "X: ${node.position.dx.toStringAsFixed(1)}, Y: ${node.position.dy.toStringAsFixed(1)}"),
              
              const Divider(height: 32),
              
              _buildSection("Downward Constraints"),
              _buildValue("minWidth", node.inputConstraints.minWidth == 0 ? "0" : node.inputConstraints.minWidth.toStringAsFixed(1)),
              _buildValue("maxWidth", node.inputConstraints.maxWidth.isInfinite ? "∞" : node.inputConstraints.maxWidth.toStringAsFixed(1)),
              _buildValue("minHeight", node.inputConstraints.minHeight == 0 ? "0" : node.inputConstraints.minHeight.toStringAsFixed(1)),
              _buildValue("maxHeight", node.inputConstraints.maxHeight.isInfinite ? "∞" : node.inputConstraints.maxHeight.toStringAsFixed(1)),
              
              const Divider(height: 32),
              
              _buildSection("Node Configuration"),
              ...node.properties.entries.map((e) => _buildValue(e.key, e.value.toString())),
              if (node.properties.isEmpty) const Text("No custom properties", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
