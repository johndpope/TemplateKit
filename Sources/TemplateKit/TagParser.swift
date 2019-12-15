//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class TagParser {
    
    public enum Error: Swift.Error {
        case invalidTag(index: String.Index)
    }
        
    public init() {
        //
    }
    
    public func parse(_ string: String) throws -> Tag {
        
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        scanner.caseSensitive = true
        
        scanner.scanWhiteSpace()
        
        if let tag = try scanIf(scanner) {
            return tag
        } else if let tag = try scanFor(scanner) {
            return tag
        } else if let tag = try scanElse(scanner) {
            return tag
        } else if let tag = try scanEnd(scanner) {
            return tag
        } else if let tag = try scanVariable(scanner) {
            return tag
        } else {
            throw Error.invalidTag(index: scanner.currentIndex)
        }
    }
    
    private func scanIf(_ scanner: Scanner) throws -> Tag? {
        let backtrackIndex = scanner.currentIndex
        guard scanner.scanString("if") != nil else {
            return nil
        }
        
        guard scanner.scanWhiteSpace() != nil else {
            if scanner.isAtEnd {
                throw Error.invalidTag(index: backtrackIndex)
            }
            scanner.currentIndex = backtrackIndex
            return nil
        }
        
        let conditionalTokens = try ConditionLexer().tokenize(scanner)
        let condition = try ConditionParser().parse(conditionalTokens)
        
        return .if(condition: condition)
    }
    
    private func scanFor(_ scanner: Scanner) throws -> Tag? {
        let backtrackIndex = scanner.currentIndex
        guard scanner.scanString("for") != nil else {
            return nil
        }
        guard scanner.scanWhiteSpace() != nil else {
            if scanner.isAtEnd {
                throw Error.invalidTag(index: backtrackIndex)
            }
            scanner.currentIndex = backtrackIndex
            return nil
        }
        guard let variable = scanner.scanIdentifier() else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        guard scanner.scanWhiteSpace() != nil else {
            scanner.currentIndex = backtrackIndex
            return nil
        }
        guard scanner.scanString("in") != nil else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        
        guard scanner.scanWhiteSpace() != nil else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        guard let sequence = scanner.scanIdentifier() else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        scanner.scanWhiteSpace()
        guard scanner.isAtEnd else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        return .for(variable: variable, sequence: sequence)
    }

    private func scanElse(_ scanner: Scanner) throws -> Tag? {
        let backtrackIndex = scanner.currentIndex
        guard scanner.scanString("else") != nil else {
            return nil
        }
        scanner.scanWhiteSpace()
        guard scanner.isAtEnd else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        return .else
    }
    
    private func scanEnd(_ scanner: Scanner) throws -> Tag? {
        let backtrackIndex = scanner.currentIndex
        guard scanner.scanString("end") != nil else {
            return nil
        }
        scanner.scanWhiteSpace()
        guard scanner.isAtEnd else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        return .end
    }

    private func scanVariable(_ scanner: Scanner) throws -> Tag? {
        let backtrackIndex = scanner.currentIndex
        
        let transformers = try scanTransformers(scanner)
        
        guard let variable = scanner.scanIdentifier() else {
            scanner.currentIndex = backtrackIndex
            return nil
        }
        scanner.scanWhiteSpace()
        guard scanner.isAtEnd else {
            throw Error.invalidTag(index: backtrackIndex)
        }
        return .variable(variable, transformers: transformers)
    }
    
    private func scanTransformers(_ scanner: Scanner) throws -> [String] {
        
        let backtrackIndex = scanner.currentIndex
        
        var transformers: [String] = []
        
        while scanner.scanString("#") != nil {
            guard let transformer = scanner.scanIdentifier() else {
                throw Error.invalidTag(index: backtrackIndex)
            }
            transformers.append(transformer)
            scanner.scanWhiteSpace()
        }
        
        return transformers
    }
}
