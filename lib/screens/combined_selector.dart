import 'package:dashboard_flutter/services/nt4.dart';
import 'package:flutter/material.dart';
import '../widgets/hexagon_painter.dart';
import '../widgets/branch_painter.dart';
import 'dart:math' as math;

class CombinedSelector extends StatefulWidget {
  const CombinedSelector({
    super.key,
    required this.title,
    this.onActionChanged,
    this.onPositionChanged,
    this.onSideChanged,
  });

  final String title;
  final Function(String)? onActionChanged;
  final Function(String)? onPositionChanged;
  final Function(String)? onSideChanged;

  @override
  State<CombinedSelector> createState() => _CombinedSelectorState();
}

class _CombinedSelectorState extends State<CombinedSelector> {
  // Selected face (A-F), starting with A
  String _selectedFace = 'A';
  // Selected action (L1-L4, Algae Low, Algae High, Processor, Barge), starting with L1
  String _selectedAction = 'L1';
  // Selected side (Left or Right), starting with Left
  String _selectedSide = 'Left';
  // High stow position toggle
  bool _highStowPosition = false;

  static const bool kDebugMode = false;

  static const String _robotAddress = kDebugMode ? '127.0.0.1' : '10.28.75.2';

  static late NT4Client _client;
  static bool _connected = false;

  static late NT4Topic actionTopic;
  static late NT4Topic sideTopic;
  static late NT4Topic positionTopic;
  static late NT4Topic highStowTopic;

  _CombinedSelectorState() {
    _client = NT4Client(
      serverBaseAddress: _robotAddress,
      onConnect: () {
        _connected = true;
        // if (_shouldSendOnConnect) {
        //   Future.delayed(const Duration(milliseconds: 200), () => _sendAll());
        // }
      },
      onDisconnect: () {
        _connected = false;
        // _shouldSendOnConnect = true;
      },
    );

    actionTopic = _client.publishNewTopic(
      '/SmartDashboard/ConsoleDriverAction',
      NT4TypeStr.STR,
    );
    sideTopic = _client.publishNewTopic(
      '/SmartDashboard/ConsoleCoralSide',
      NT4TypeStr.STR,
    );
    positionTopic = _client.publishNewTopic(
      '/SmartDashboard/ConsoleCoralPosition',
      NT4TypeStr.STR,
    );
    highStowTopic = _client.publishNewTopic(
      '/SmartDashboard/ConsoleHighStowPosition',
      NT4TypeStr.BOOL,
    );

    _client.addSample(actionTopic, "L1");
    _client.addSample(sideTopic, "Left");
    _client.addSample(positionTopic, "A");
    _client.addSample(highStowTopic, false);
  }

  void _selectFace(String face) {
    if (_selectedFace != face) {
      setState(() {
        _selectedFace = face;
      });

      // Call the callback if provided
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(face);
      }

      // Log the change
      // _logSelectionChange('Position', face);
      _client.addSample(positionTopic, face);
    }
  }

  void _selectAction(String action) {
    if (_selectedAction != action) {
      setState(() {
        _selectedAction = action;
      });

      // Call the callback if provided
      if (widget.onActionChanged != null) {
        widget.onActionChanged!(action);
      }

      // Log the change
      _logSelectionChange('Action', action);
      _client.addSample(actionTopic, action);
    }
  }

  void _selectSide(String side) {
    if (_selectedSide != side) {
      setState(() {
        _selectedSide = side;
      });

      // Call the callback if provided
      if (widget.onSideChanged != null) {
        widget.onSideChanged!(side);
      }

      // Log the change
      // _logSelectionChange('Side', side);
      _client.addSample(sideTopic, side);
    }
  }

  // Handle high stow position toggle
  void _toggleHighStowPosition(bool value) {
    setState(() {
      _highStowPosition = value;
    });

    // Log the change
    _logSelectionChange('High Stow Position', value.toString());
    _client.addSample(highStowTopic, value);
  }

  // Helper method to log selection changes
  void _logSelectionChange(String type, String value) {
    debugPrint('$type changed to: $value');
  }

  @override
  Widget build(BuildContext context) {
    // Calculate button positions based on hexagon geometry
    final double hexRadius = 150; // Increased from 125
    final double buttonDistance =
        hexRadius * 0.8; // Distance from center to button

    // Calculate positions for each face button
    // For a regular hexagon with flat sides at top and bottom
    final Map<String, Offset> buttonPositions = {
      // Calculate the center point of each face in clockwise order
      'A': Offset(0, buttonDistance), // Bottom (0 degrees)
      'F': Offset(
        buttonDistance * 0.866,
        buttonDistance * 0.5,
      ), // Bottom-right (30 degrees) - was B
      'E': Offset(
        buttonDistance * 0.866,
        -buttonDistance * 0.5,
      ), // Top-right (150 degrees) - was C
      'D': Offset(0, -buttonDistance), // Top (180 degrees) - unchanged
      'C': Offset(
        -buttonDistance * 0.866,
        -buttonDistance * 0.5,
      ), // Top-left (210 degrees) - was E
      'B': Offset(
        -buttonDistance * 0.866,
        buttonDistance * 0.5,
      ), // Bottom-left (330 degrees) - was F
    };

    // Get the screen size to calculate button sizes
    final Size screenSize = MediaQuery.of(context).size;
    final double baseButtonSize =
        math.min(screenSize.width, screenSize.height) * 0.06;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Combined selection display
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Position: $_selectedFace',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Action: $_selectedAction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedAction.contains('Algae')
                          ? Colors.green.shade300
                          : _selectedAction == 'Processor'
                              ? Colors.orange.shade300
                              : _selectedAction == 'Barge'
                                  ? Colors.purple.shade300
                                  : _selectedAction == 'Feeder'
                                      ? Colors.red.shade300
                                      : _selectedAction == 'Cage'
                                          ? Colors.amber.shade300
                                          : Colors.blue.shade300,
                    ),
                  ),
                  Text(
                    'Side: $_selectedSide',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'High Stow: ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _highStowPosition ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _highStowPosition
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Main selectors row
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Face selector
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Position',
                          style: TextStyle(
                            fontSize: 24, // Increased from 20
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity, // Take full width
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double width = constraints.maxWidth;
                                final double height = constraints.maxHeight;

                                // Calculate hexagon center and size based on available space
                                final double hexSize =
                                    math.min(width, height) * 0.9;
                                final double hexCenterX = width / 2;
                                final double hexCenterY = height / 2;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Hexagon visualization
                                    CustomPaint(
                                      size: Size(hexSize, hexSize),
                                      painter: HexagonPainter(
                                        selectedFace: _selectedFace,
                                      ),
                                    ),

                                    // Generate face buttons at calculated positions
                                    ...buttonPositions.entries.map((entry) {
                                      final String face = entry.key;
                                      final Offset position = entry.value;

                                      // Calculate button position based on hexagon size
                                      final double buttonX = hexCenterX +
                                          (position.dx / buttonDistance) *
                                              (hexSize / 2) *
                                              0.7;
                                      final double buttonY = hexCenterY +
                                          (position.dy / buttonDistance) *
                                              (hexSize / 2) *
                                              0.7;

                                      // Calculate button size based on hexagon size
                                      final double buttonSize = hexSize * 0.15;
                                      // Account for the 1.5x scaling in _buildFaceButton
                                      final double actualButtonSize =
                                          buttonSize * 1.5;

                                      return Positioned(
                                        left: buttonX -
                                            actualButtonSize /
                                                2, // Center the button on the position
                                        top: buttonY -
                                            actualButtonSize /
                                                2, // Center the button on the position
                                        child: _buildFaceButton(
                                          face,
                                          buttonSize,
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action and Side selectors
                  Expanded(
                    child: Column(
                      children: [
                        // Action selector
                        const Text(
                          'Action',
                          style: TextStyle(
                            fontSize: 24, // Increased from 20
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity, // Take full width
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double width = constraints.maxWidth;
                                final double height = constraints.maxHeight;

                                // Calculate branch dimensions to match BranchPainter
                                final double mainPipeWidth = width * 0.9 * 0.15;
                                final double mainPipeLeft =
                                    width / 2 - mainPipeWidth / 2;
                                final double branchWidth = width * 0.9 * 0.35;
                                final double branchHeight = height * 0.9 * 0.12;

                                // Branch positions from BranchPainter
                                final List<double> branchPositions = [
                                  height * 0.9 * 0.65, // L2 (bottom branch)
                                  height * 0.9 * 0.35, // L3 (middle branch)
                                  height * 0.9 * 0.05, // L4 (top branch)
                                ];

                                // Shelf dimensions for L1
                                final double shelfStartX =
                                    mainPipeLeft + mainPipeWidth;
                                final double shelfStartY =
                                    height * 0.9 * 0.9; // Position near bottom
                                final double shelfWidth = width * 0.9 * 0.35;
                                final double shelfHeight = height * 0.9 * 0.08;
                                final double shelfEndX =
                                    shelfStartX + shelfWidth;
                                final double shelfEndY = shelfStartY +
                                    shelfHeight * 0.3; // Slight tilt downward

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Branch visualization
                                    CustomPaint(
                                      size: Size(width * 0.9, height * 0.9),
                                      painter: BranchPainter(
                                        selectedLevel: _selectedAction
                                                .startsWith('L')
                                            ? _selectedAction
                                            : 'L1', // Default to L1 for branch painter if algae is selected
                                        isAlgaeSelected: _selectedAction
                                                .contains('Algae') ||
                                            _selectedAction == 'Processor' ||
                                            _selectedAction == 'Barge' ||
                                            _selectedAction == 'Feeder' ||
                                            _selectedAction == 'Cage',
                                      ),
                                    ),

                                    // Cage visualization - ABOVE BARGE\
                                    Positioned(
                                      left: width * 0.05, // Left aligned
                                      top: height * 0.05, // Moved down slightly
                                      child: Container(
                                        width: width * 0.3, // Shrunk width
                                        height: height * 0.2, // Shrunk height
                                        decoration: BoxDecoration(
                                          color: _selectedAction == 'Cage'
                                              ? Colors.amber.shade200
                                              : Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: width * 0.2,
                                            height: height * 0.15,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: _buildCageButton(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Barge visualization (trough with button) - TOP
                                    Positioned(
                                      left: width * 0.05, // Left aligned
                                      top: height * 0.28, // Moved down slightly
                                      child: Container(
                                        width: width * 0.3, // Shrunk width
                                        height: height * 0.2, // Shrunk height
                                        decoration: BoxDecoration(
                                          color: _selectedAction == 'Barge'
                                              ? Colors.purple.shade200
                                              : Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: width * 0.25,
                                            height: height * 0.15,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade600,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft: Radius.circular(
                                                  30,
                                                ),
                                                bottomRight:
                                                    Radius.circular(30),
                                              ),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: _buildBargeButton(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Processor visualization (rectangle with inner rectangle) - MIDDLE
                                    Positioned(
                                      left: width * 0.05, // Left aligned
                                      top: height * 0.52, // Moved down slightly
                                      child: Container(
                                        width: width * 0.3, // Shrunk width
                                        height: height * 0.2, // Shrunk height
                                        decoration: BoxDecoration(
                                          color: _selectedAction == 'Processor'
                                              ? Colors.orange.shade200
                                              : Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: width * 0.2,
                                            height: height * 0.15,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: _buildProcessorButton(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Feeder Intake visualization - BOTTOM
                                    Positioned(
                                      left: width * 0.05, // Left aligned
                                      top: height * 0.75, // Moved down slightly
                                      child: Container(
                                        width: width * 0.3, // Shrunk width
                                        height: height * 0.2, // Shrunk height
                                        decoration: BoxDecoration(
                                          color: _selectedAction == 'Feeder'
                                              ? Colors.red.shade200
                                              : Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: width * 0.2,
                                            height: height * 0.15,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: _buildFeederButton(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // L1 button (on the shelf)
                                    Positioned(
                                      left: shelfEndX -
                                          width *
                                              0.12, // End of shelf minus half button width
                                      top: shelfEndY -
                                          height *
                                              0.03, // Adjust to center on shelf
                                      child: _buildActionButton(
                                        'L1',
                                        width * 0.12,
                                      ),
                                    ),

                                    // L2 button (bottom branch)
                                    Positioned(
                                      left: mainPipeLeft +
                                          mainPipeWidth +
                                          branchWidth -
                                          width *
                                              0.12, // End of branch minus half button width
                                      top: branchPositions[0] +
                                          branchHeight / 2 -
                                          height * 0.06, // Center on branch
                                      child: _buildActionButton(
                                        'L2',
                                        width * 0.12,
                                      ),
                                    ),

                                    // Algae Low (between L2 and L3)
                                    Positioned(
                                      left: mainPipeLeft +
                                          mainPipeWidth +
                                          branchWidth +
                                          10, // End of branch + fixed offset
                                      top: (branchPositions[0] +
                                                  branchPositions[1]) /
                                              2 -
                                          height *
                                              0.05, // Halfway between L2 and L3
                                      child: _buildAlgaeButton(
                                        'Algae Low',
                                        width * 0.1,
                                      ),
                                    ),

                                    // L3 button (middle branch)
                                    Positioned(
                                      left: mainPipeLeft +
                                          mainPipeWidth +
                                          branchWidth -
                                          width *
                                              0.12, // End of branch minus half button width
                                      top: branchPositions[1] +
                                          branchHeight / 2 -
                                          height * 0.06, // Center on branch
                                      child: _buildActionButton(
                                        'L3',
                                        width * 0.12,
                                      ),
                                    ),

                                    // Algae High (between L3 and L4)
                                    Positioned(
                                      left: mainPipeLeft +
                                          mainPipeWidth +
                                          branchWidth +
                                          10, // End of branch + fixed offset
                                      top: (branchPositions[1] +
                                                  branchPositions[2]) /
                                              2 -
                                          height *
                                              0.05, // Halfway between L3 and L4
                                      child: _buildAlgaeButton(
                                        'Algae High',
                                        width * 0.1,
                                      ),
                                    ),

                                    // L4 button (top branch)
                                    Positioned(
                                      left: mainPipeLeft +
                                          mainPipeWidth +
                                          branchWidth -
                                          width *
                                              0.12, // End of branch minus half button width
                                      top: branchPositions[2] +
                                          branchHeight / 2 -
                                          height * 0.06, // Center on branch
                                      child: _buildActionButton(
                                        'L4',
                                        width * 0.12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // Side selector (Left/Right)
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // High Stow Position Toggle on the left
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 75,
                                padding: const EdgeInsets.only(right: 16.0),
                                child: ElevatedButton(
                                  onPressed: () => _toggleHighStowPosition(
                                      !_highStowPosition),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _highStowPosition
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: _highStowPosition ? 8 : 4,
                                  ),
                                  child: const Text(
                                    'High Stow',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Side selector title and buttons
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  const Text(
                                    'Side',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth;
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildSideButton('Left', width * 0.4),
                                          const SizedBox(width: 20),
                                          _buildSideButton('Right', width * 0.4),
                                        ],
                                      );
                                    }
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceButton(String face, double size) {
    bool isSelected = _selectedFace == face;

    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: ElevatedButton(
        onPressed: () => _selectFace(face),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          face,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton(String action, double size) {
    bool isSelected = _selectedAction == action;

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => _selectAction(action),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          action,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAlgaeButton(String algae, double size) {
    bool isSelected = _selectedAction == algae;

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => _selectAction(algae),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.green.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          algae.split(
            ' ',
          )[1][0], // Just show first letter of second word (L or H)
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProcessorButton() {
    bool isSelected = _selectedAction == 'Processor';

    // Calculate button size based on the parent container
    final double buttonSize = MediaQuery.of(context).size.width * 0.05;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: () => _selectAction('Processor'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.orange.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          'P',
          style: TextStyle(
            fontSize: buttonSize * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBargeButton() {
    bool isSelected = _selectedAction == 'Barge';

    // Get the context size
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.06;
    final double buttonHeight = screenSize.width * 0.04;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: () => _selectAction('Barge'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.purple.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight * 0.3),
          ),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          'B',
          style: TextStyle(
            fontSize: buttonHeight * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeederButton() {
    bool isSelected = _selectedAction == 'Feeder';

    // Get the context size
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.06;
    final double buttonHeight = screenSize.width * 0.04;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: () => _selectAction('Feeder'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.red.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight * 0.3),
          ),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          'F',
          style: TextStyle(
            fontSize: buttonHeight * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCageButton() {
    bool isSelected = _selectedAction == 'Cage';

    // Get the context size
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.06;
    final double buttonHeight = screenSize.width * 0.04;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: () => _selectAction('Cage'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.amber.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight * 0.3),
          ),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          'C',
          style: TextStyle(
            fontSize: buttonHeight * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton(String side, double width) {
    bool isSelected = _selectedSide == side;

    final double height = width * 0.5;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: () => _selectSide(side),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height * 0.2),
          ),
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          side,
          style: TextStyle(fontSize: height * 0.4, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
