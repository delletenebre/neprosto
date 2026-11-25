part of 'project_templates.dart';

extension _Framing on _Parts {
  void gardenGate() {
    final s = editorStrings, lower = board, upper = h - 2.25 * board;
    for (final z in [lower, upper]) {
      front(s.frameRail, 0, 0, z, w, stud, board);
    }
    final n = 9;
    for (var i = 0; i < n; i++) {
      final inset = [
        board,
        measure(50, 2),
        measure(22, .875),
        measure(6, .25),
        0.0,
      ];
      final height = h - inset[4 - (i - 4).abs()];
      add(
        s.gatePicket,
        i * (w - board) / (n - 1),
        stud,
        0,
        height,
        board,
        d - stud,
        2,
        0,
      );
    }
    member(
      s.bridging,
      Vector3(board, stud / 2, lower + board),
      Vector3(w - board, stud / 2, upper),
      axis(1),
      board,
      stud,
      startPlane: axis(2),
      endPlane: axis(2),
    );
  }
}
