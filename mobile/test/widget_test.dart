import "package:dentapro_mobile/main.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("login presents patient and dentist entry points",
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());

    expect(find.text("Dentapro"), findsOneWidget);
    expect(find.text("SOY PACIENTE"), findsOneWidget);
    expect(find.text("ACCESO ODONTÓLOGOS"), findsOneWidget);
  });

  testWidgets("patient entry opens the sample dashboard", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();

    expect(find.text("Hola, Camila"), findsOneWidget);
    expect(find.text("Limpieza y revisión"), findsOneWidget);
    expect(find.text("Accesos rápidos"), findsOneWidget);
  });

  testWidgets("quick-access sections provide placeholder feedback", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Historial"));
    await tester.pump();

    expect(find.text("Tu historial estará disponible próximamente."),
        findsOneWidget);
  });
}
