//
//  GeneratorTests.swift
//  BeaverDICodeGenTests
//
//  Created by Théophane Rupin on 3/4/18.
//

import Foundation
import XCTest
import SourceKittenFramework
import PathKit

@testable import BeaverDICodeGen

final class GeneratorTests: XCTestCase {
    
    let templatePath = Path(#file).parent() + Path("../../Resources/dependency_resolver.stencil")
    
    func test_generator_should_generate_a_valid_swift_code() {
        
        do {
            let file = File(contents: """
final class MyService {
  let dependencies: DependencyResolver

  // beaverdi: api = API <- APIProtocol
  // beaverdi: api.scope = .graph
  // beaverdi: api.customRef = true

  // beaverdi: apiBis = API <- APIProtocol
  // beaverdi: apiBis.scope = .container

  // beaverdi: router = Router <- RouterProtocol
  // beaverdi: router.scope = .container

  // beaverdi: session = Session

  final class MyEmbeddedService {

    // beaverdi: session = Session? <- SessionProtocol?
    // beaverdi: session.scope = .container

    // beaverdi: api <- APIProtocol

    // beaverdi: apiBis <- APIProtocol
  }

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}

final class API: APIProtocol {
    // beaverdi: parameter <= UInt
}

class AnotherService {
    // This class is ignored
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            
            let generator = try Generator(asts: [ast], template: templatePath)
            let (_ , string) = try generator.generate().first!
            
            XCTAssertEqual(string!, """
/// This file is generated by BeaverDI
/// DO NOT EDIT!
import BeaverDI
// MARK: - MyService
final class MyServiceDependencyContainer: DependencyContainer {
    init() {
        super.init()
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(APIProtocol.self, scope: .graph, name: "api", builder: { (dependencies, parameter: UInt) in
            return self.apiCustomRef(dependencies, parameter: parameter)
        })
        store.register(RouterProtocol.self, scope: .container, name: "router", builder: { (dependencies) in
            return Router.makeRouter(injecting: dependencies)
        })
        store.register(Session.self, scope: .graph, name: "session", builder: { (dependencies) in
            return Session.makeSession(injecting: dependencies)
        })
        store.register(APIProtocol.self, scope: .container, name: "apiBis", builder: { (dependencies, parameter: UInt) in
            return API.makeAPI(injecting: dependencies, parameter: parameter)
        })
    }
}
protocol MyServiceDependencyResolver {
    func api(parameter: UInt) -> APIProtocol
    var router: RouterProtocol { get }
    var session: Session { get }
    func apiBis(parameter: UInt) -> APIProtocol
    func apiCustomRef(_ dependencies: DependencyContainer, parameter: UInt) -> APIProtocol
}
extension MyServiceDependencyContainer: MyServiceDependencyResolver {
    func api(parameter: UInt) -> APIProtocol {
        return resolve(APIProtocol.self, name: "api", parameter: parameter)
    }
    var router: RouterProtocol {
        return resolve(RouterProtocol.self, name: "router")
    }
    var session: Session {
        return resolve(Session.self, name: "session")
    }
    func apiBis(parameter: UInt) -> APIProtocol {
        return resolve(APIProtocol.self, name: "apiBis", parameter: parameter)
    }
}
// MARK: - MyEmbeddedService
final class MyEmbeddedServiceDependencyContainer: DependencyContainer {
    init(parent: DependencyContainer) {
        super.init(parent)
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(SessionProtocol?.self, scope: .container, name: "session", builder: { (dependencies) in
            return Session.makeSession(injecting: dependencies)
        })
    }
}
protocol MyEmbeddedServiceDependencyResolver {
    var session: SessionProtocol? { get }
    func api(parameter: UInt) -> APIProtocol
    func apiBis(parameter: UInt) -> APIProtocol
}
extension MyEmbeddedServiceDependencyContainer: MyEmbeddedServiceDependencyResolver {
    var session: SessionProtocol? {
        return resolve(SessionProtocol?.self, name: "session")
    }
    func api(parameter: UInt) -> APIProtocol {
        return resolve(APIProtocol.self, name: "api", parameter: parameter)
    }
    func apiBis(parameter: UInt) -> APIProtocol {
        return resolve(APIProtocol.self, name: "apiBis", parameter: parameter)
    }
}
extension MyService.MyEmbeddedService {
    static func makeMyEmbeddedService(injecting parentDependencies: DependencyContainer) -> MyEmbeddedService {
        let dependencies = MyEmbeddedServiceDependencyContainer(parent: parentDependencies)
        return MyEmbeddedService(injecting: dependencies)
    }
}
protocol MyEmbeddedServiceDependencyInjectable {
    init(injecting dependencies: MyEmbeddedServiceDependencyResolver)
}
extension MyService.MyEmbeddedService: MyEmbeddedServiceDependencyInjectable {}
// MARK: - API
final class APIDependencyContainer: DependencyContainer {
    let parameter: UInt
    init(parameter: UInt) {
        self.parameter = parameter
        super.init()
    }
    override func registerDependencies(in store: DependencyStore) {
    }
}
protocol APIDependencyResolver {
    var parameter: UInt { get }
}
extension APIDependencyContainer: APIDependencyResolver {
}
""")
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_return_nil_when_no_annotation_is_detected() {
        
        do {
            let file = File(contents: """
final class MyService {
  let dependencies: DependencyResolver

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            
            let generator = try Generator(asts: [ast], template: templatePath)
            let (_ , string) = try generator.generate().first!

            XCTAssertNil(string)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
