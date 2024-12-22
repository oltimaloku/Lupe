//
//  ConceptView.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2024-11-23.
//

import SwiftUI
import MarkdownUI

struct ConceptView: View {
    let concept: Concept
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(concept.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)
                
                if let definition = concept.definition {
                    Markdown(definition)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    Text("No definition available")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ConceptView(concept: Concept(
        id: UUID(),
        name: "Stock",
        definition: """
        # Stock
                                 
        A **stock** represents a share in the ownership of a company. Holding a stock entitles the owner to a portion of the company’s assets and earnings, proportional to the amount of stock owned. Stocks are also known as **equities**.

        ## Key Characteristics
        - **Ownership**: Each share represents a fractional ownership of the company.
        - **Dividends**: Some stocks provide dividends, which are regular payments made to shareholders from the company’s profits.
        - **Capital Gains**: Stocks can increase in value over time, allowing shareholders to sell their shares at a higher price than they were purchased for.
        - **Risk and Reward**: Stocks typically carry higher risks compared to other investments like bonds but also offer higher potential returns.

        ## Types of Stocks
        1. **Common Stock**: Provides voting rights and potential dividends.
        2. **Preferred Stock**: Offers fixed dividends and has priority over common stock in case of liquidation but usually does not carry voting rights.

        ## How Stocks are Traded
        Stocks are bought and sold on stock exchanges like the **New York Stock Exchange (NYSE)** or **Nasdaq**, where investors can trade shares during market hours.

        ### Example
        - Buying 10 shares of a company at $100/share gives you a $1,000 stake in the company.
        """
    ))
}
