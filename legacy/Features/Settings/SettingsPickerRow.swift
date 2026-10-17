import SwiftUI

struct SettingsPickerRow<Option: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let label: KeyPath<Option, String>

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(options) { option in
                    Text(option[keyPath: label]).tag(option)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
    }
}

#Preview {
    @Previewable @State var choice = HotKeyChoice.optionCommandD
    SettingsPickerRow(title: "Global shortcut", selection: $choice, options: HotKeyChoice.allCases, label: \.title)
        .padding()
}
