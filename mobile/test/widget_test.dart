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

  testWidgets("patient quick access opens the mock odontogram and history", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Odontograma"));
    await tester.pumpAndSettle();

    expect(find.text("Odontograma"), findsOneWidget);
    expect(find.byKey(const Key("odontogram-chart")), findsOneWidget);

    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Historial"));
    await tester.pumpAndSettle();

    expect(find.text("Odontograma"), findsOneWidget);
    expect(find.byKey(const Key("odontogram-chart")), findsOneWidget);
    expect(find.text("ARCADA SUPERIOR"), findsOneWidget);
    expect(find.text("Sanos"), findsOneWidget);
    expect(find.text("Revisión"), findsNWidgets(2));
    expect(find.text("Urgencia"), findsNWidgets(2));
    expect(find.text("Historial de Tratamientos"), findsOneWidget);
    expect(find.text("Limpieza dental"), findsOneWidget);
    expect(find.text("Dra. Valentina Ortiz"), findsWidgets);
    expect(find.text("24 oct 2026"), findsOneWidget);
  });

  testWidgets("dashboard search opens the clinic catalog", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();

    expect(find.text("Encuentra tu clínica"), findsOneWidget);
    expect(find.text("Clínica Sonríe"), findsOneWidget);
    expect(find.text("Dra. Valentina Ortiz"), findsOneWidget);
  });

  testWidgets("clinic search filters the sample listings", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key("clinic-search-field")),
      "Mateo Ruiz",
    );
    await tester.pumpAndSettle();

    expect(find.text("Clínica Nova"), findsOneWidget);
    expect(find.text("Clínica Sonríe"), findsNothing);
    expect(find.text("Sonrisa Kids"), findsNothing);
  });

  testWidgets("reservation screen shows calendar, slots, and mock summary", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.text("SOY PACIENTE"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reservar cita").first);
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text("Horarios disponibles"), findsOneWidget);
    expect(find.text("09:00"), findsOneWidget);
    expect(find.text("10:30"), findsNWidgets(2));
    expect(find.text("Resumen de reserva"), findsOneWidget);
    expect(find.text("Confirmar y Pagar"), findsOneWidget);

    await tester.tap(find.text("09:00"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Confirmar y Pagar"));
    await tester.pump();

    expect(
      find.text("Vista previa: no se realizó ningún cobro."),
      findsOneWidget,
    );
  });
}
