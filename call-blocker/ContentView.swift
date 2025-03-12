
import SwiftUI
import CallKit

struct ContentView: View {
    @State private var countryCode: String = ""
    @State private var prefix: String = ""
    @State private var blockedNumbers: [String] = []
    @State private var showCallBlockingAlert = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.95) // Fondo claro
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Call Blocker by Prefix")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                VStack(spacing: 15) {
                    CustomTextField(placeholder: Text("Country code (e.g. +1, +52)"), text: $countryCode)
                    CustomTextField(placeholder: Text("Prefix or number to block"), text: $prefix)
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(15)
                
                Button(action: {
                    hideKeyboard()
                    isLoading = true
                    checkCallBlockingPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                }) {
                    CustomButton(title: Text("Add to blocked"), color: .red)
                }
                .disabled(countryCode.isEmpty || prefix.isEmpty || isLoading)
                
                Button(action: {
                    hideKeyboard()
                    clearBlockedNumbers()
                }) {
                    CustomButton(title: Text("Delete All"), color: .red)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                
                List(blockedNumbers, id: \.self) { number in
                    HStack {
                        Text(number)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            removeBlockedNumber(number)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.8))
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .padding()
        }
        .onAppear {
            loadBlockedNumbers()
        }
        .alert(isPresented: $showCallBlockingAlert) {
            Alert(
                title: Text("Activate Caller ID"),
                message: Text("To block calls, activate the extension in Settings > Phone > Call Blocking & Identification > Call Blocker by Prefix"),
                primaryButton: .default(Text("Go to Settings")) {
                    if let url = URL(string: "App-Prefs:root=Phone&path=CallBlocking"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Función para ocultar el teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Verifica si el identificador de llamadas está activado antes de agregar números
    private func checkCallBlockingPermission() {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: "hdz.ivan.callblocker.extension", completionHandler: { status, error in
            DispatchQueue.main.async {
                if status == .enabled {
                    addPrefixToBlockList()
                } else {
                    showCallBlockingAlert = true
                }
            }
        })
    }

    /// Agrega un prefijo o un número completo a la lista de bloqueados
    private func addPrefixToBlockList() {
        guard !prefix.isEmpty, !countryCode.isEmpty else { return }

        let defaults = UserDefaults(suiteName: "group.hdz.ivan.callblocker")
        var numbers = defaults?.array(forKey: "BlockedNumbers") as? [String] ?? []

        let normalizedCountryCode = countryCode.hasPrefix("+") ? countryCode : "+\(countryCode)"
        let fullNumber = "\(normalizedCountryCode)\(prefix)"

        if prefix.count == 10 {
            // Si es un número completo, solo se agrega ese número
            if !numbers.contains(fullNumber) {
                numbers.append(fullNumber)
            }
        } else {
            // Si es un prefijo, generar el rango restante
            let remainingDigits = 10 - prefix.count
            let maxNumber = Int(pow(10.0, Double(remainingDigits))) - 1

            for i in 0...maxNumber {
                let formattedNumber = "\(fullNumber)\(String(format: "%0\(remainingDigits)d", i))"
                if !numbers.contains(formattedNumber) {
                    numbers.append(formattedNumber)
                }
            }
        }

        defaults?.set(numbers, forKey: "BlockedNumbers")

        reloadCallDirectory()
        loadBlockedNumbers()
    }

    /// Carga los números bloqueados desde `UserDefaults`
    private func loadBlockedNumbers() {
        let defaults = UserDefaults(suiteName: "group.hdz.ivan.callblocker")
        blockedNumbers = defaults?.array(forKey: "BlockedNumbers") as? [String] ?? []
    }

    /// Elimina un número específico de la lista de bloqueados
    private func removeBlockedNumber(_ number: String) {
        let defaults = UserDefaults(suiteName: "group.hdz.ivan.callblocker")
        var numbers = defaults?.array(forKey: "BlockedNumbers") as? [String] ?? []

        if let index = numbers.firstIndex(of: number) {
            numbers.remove(at: index)
        }

        defaults?.set(numbers, forKey: "BlockedNumbers")
        reloadCallDirectory()
        loadBlockedNumbers()
    }

    /// Borra todos los números bloqueados
    private func clearBlockedNumbers() {
        let defaults = UserDefaults(suiteName: "group.hdz.ivan.callblocker")
        defaults?.removeObject(forKey: "BlockedNumbers")
        reloadCallDirectory()
        loadBlockedNumbers()
    }

    /// Recarga la extensión de Call Directory para aplicar los cambios
    private func reloadCallDirectory() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "hdz.ivan.callblocker.extension") { error in
            if let error = error {
                print("Error al recargar Call Directory: \(error.localizedDescription)")
            } else {
                print("Call Directory recargado correctamente")
            }
        }
    }
}

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: placeholder.foregroundStyle(.gray))
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .keyboardType(.phonePad)
            .foregroundStyle(.black)
            
            
    }
}


struct CustomButton: View {
    var title: Text
    var color: Color
    
    var body: some View {
        title
            .foregroundColor(.white)
            .bold()
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(10)
    }
}
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
