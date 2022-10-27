//  Created by Dominik Hauser on 26.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI

struct NoEntriesView: View {
  var body: some View {
    VStack(spacing: 10) {
      Text("No entries yet.")
        .font(.title)
      Text("Keep this app on your iPhone and grant it the authorisation to 'Always' track your location when iOS asks you about it.*")
      Spacer()
      Text("*Don't worry! This app only needs 'Always' authorisation to get notified when you exit or enter the registered regions. This information never leaves your device.")
        .font(.footnote)
    }
    .padding()
  }
}

struct NoEntriesView_Previews: PreviewProvider {
  static var previews: some View {
    NoEntriesView()
  }
}
