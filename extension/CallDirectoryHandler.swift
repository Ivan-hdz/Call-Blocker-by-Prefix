//
//  CallDirectoryHandler.swift
//  extension
//
//  Created by ivan on 11/03/25.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        print("✅ beginRequest ejecutado en la extensión")

        // Cargar números y agregar entradas
        let blockedNumbers = loadBlockedNumbers()
        print("📌 Números bloqueados obtenidos: \(blockedNumbers.count)")

        for number in blockedNumbers {
            print("📲 Agregando número: \(number)")
            context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }

        // Marcar como completado solo después de agregar todas las entradas
        context.completeRequest(completionHandler: { _ in
            print("🚀 Solicitud completada")
        })
    }
    /// Carga los números bloqueados desde UserDefaults
    private func loadBlockedNumbers() -> [Int64] {
        let defaults = UserDefaults(suiteName: "group.hdz.ivan.callblocker")
        guard let numbers = defaults?.array(forKey: "BlockedNumbers") as? [String] else { // ⚠️ Verifica la key ("BlockedNumbers")
            print("❌ No se encontraron números bloqueados")
            return []
        }

        let blockedNumbers = numbers.compactMap { num -> Int64? in
            let cleanedNumber = num.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: " ", with: "")
            return cleanedNumber.isEmpty ? nil : Int64(cleanedNumber)
        }

        print("📌 Números cargados en extensión: \(blockedNumbers)")
        return blockedNumbers
    }
}


extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occurred while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
        print(error)
    }

}
