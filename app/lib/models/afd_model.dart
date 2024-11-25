class AFDModel {
  // Mapa de transiciones
  Map<String, Map<String, String>> transitions = {
    "q0": {"valid": "q1", "invalid": "q0"}, // Desde q0 a q1 con "valid"
    "q1": {"valid": "q2", "invalid": "q0"}, // Desde q1 a q2 con "valid"
    "q2": {"valid": "qFinal", "invalid": "q0"}, // Desde q2 a qFinal con "valid"
    "qFinal": {"valid": "q0", "invalid": "q0"}, // Desde qFinal reinicia a q0
  };

  String state = "q0"; // Estado inicial

  // Procesar la entrada y manejar las transiciones
  String? processInput(String inputSymbol) {
    print('Procesando símbolo de entrada: $inputSymbol');

    // Verifica si el símbolo de entrada es válido para la transición desde el estado actual
    if (transitions[state]?.containsKey(inputSymbol) == true) {
      state = transitions[state]![inputSymbol]!;
      print('Estado después de la transición: $state');
    } else {
      print('Símbolo de entrada no reconocido en estado $state');
    }

    // Verifica el estado actual y devuelve un resultado dependiendo del estado
    if (state == "q2") {
      return "Estado q2 alcanzado"; // En el estado q2, muestra un mensaje
    } else if (state == "qFinal") {
      return "Número Maya detectado correctamente"; // En el estado final, muestra el resultado
    }

    return null;
  }

  void reset() {
    state = "q0"; // Reinicia el autómata a su estado inicial
  }
}
