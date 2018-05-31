//
//  GeneratorTests.swift
//  WeaverCodeGenTests
//
//  Created by Théophane Rupin on 3/4/18.
//

import Foundation
import XCTest
import SourceKittenFramework
import PathKit

@testable import WeaverCodeGen

final class GeneratorTests: XCTestCase {
    
    private let templatePath = Path(#file).parent() + Path("../../Resources/dependency_resolver.stencil")
    private let version = "0.9.8"
    
    func test_generator_should_generate_a_valid_swift_code() {
        
        do {
            let file = File(contents: """
public final class MyService {
  let dependencies: DependencyResolver

  // weaver: api = API <- APIProtocol
  // weaver: api.scope = .graph
  // weaver: api.customRef = true

  // weaver: apiBis = API <- APIProtocol
  // weaver: apiBis.scope = .container

  // weaver: router = Router <- RouterProtocol
  // weaver: router.scope = .container

  // weaver: session = Session

  final class MyEmbeddedService {

    // weaver: session = Session? <- SessionProtocol?
    // weaver: session.scope = .container

    // weaver: api <- APIProtocol

    // weaver: apiBis <- APIProtocol
  }

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}

final class API: APIProtocol {
    // weaver: parameter <= UInt
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
/// This file is generated by Weaver \(version)
/// DO NOT EDIT!
import WeaverDI
// MARK: - MyService
public final class MyServiceDependencyContainer: DependencyContainer {
    public init() {
        super.init()
    }
    override public func registerDependencies(in store: DependencyStore) {
        store.register(APIProtocol.self, scope: .graph, name: "api", builder: { (dependencies, parameter: UInt) in
            return self.apiCustomRef(dependencies, parameter: parameter)
        })
        store.register(RouterProtocol.self, scope: .container, name: "router", builder: { (dependencies) in
            return Router()
        })
        store.register(Session.self, scope: .graph, name: "session", builder: { (dependencies) in
            return Session()
        })
        store.register(APIProtocol.self, scope: .container, name: "apiBis", builder: { (dependencies, parameter: UInt) in
            return API.makeAPI(injecting: dependencies, parameter: parameter)
        })
    }
}
public protocol MyServiceDependencyResolver {
    func api(parameter: UInt) -> APIProtocol
    var router: RouterProtocol { get }
    var session: Session { get }
    func apiBis(parameter: UInt) -> APIProtocol
    func apiCustomRef(_ dependencies: DependencyContainer, parameter: UInt) -> APIProtocol
}
extension MyServiceDependencyContainer: MyServiceDependencyResolver {
    public func api(parameter: UInt) -> APIProtocol {
        return resolve(APIProtocol.self, name: "api", parameter: parameter)
    }
    public var router: RouterProtocol {
        return resolve(RouterProtocol.self, name: "router")
    }
    public var session: Session {
        return resolve(Session.self, name: "session")
    }
    public func apiBis(parameter: UInt) -> APIProtocol {
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
            return Session()
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
    
    func test_generator_should_generate_a_valid_swift_code_when_an_empty_type_gets_registered() {
        
        do {
            let file = File(contents: """
final class Logger {
    func log(_ message: String) { print(message) }

    // weaver: logEngine = LogEngine
}

final class Manager {
    // weaver: logger = Logger
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            
            let generator = try Generator(asts: [ast], template: templatePath)
            let (_ , string) = try generator.generate().first!
            
            XCTAssertEqual(string!, """
/// This file is generated by Weaver \(version)
/// DO NOT EDIT!
import WeaverDI
// MARK: - Logger
final class LoggerDependencyContainer: DependencyContainer {
    init() {
        super.init()
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(LogEngine.self, scope: .graph, name: "logEngine", builder: { (dependencies) in
            return LogEngine()
        })
    }
}
protocol LoggerDependencyResolver {
    var logEngine: LogEngine { get }
}
extension LoggerDependencyContainer: LoggerDependencyResolver {
    var logEngine: LogEngine {
        return resolve(LogEngine.self, name: "logEngine")
    }
}
// MARK: - Manager
final class ManagerDependencyContainer: DependencyContainer {
    init() {
        super.init()
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(Logger.self, scope: .graph, name: "logger", builder: { (dependencies) in
            return Logger()
        })
    }
}
protocol ManagerDependencyResolver {
    var logger: Logger { get }
}
extension ManagerDependencyContainer: ManagerDependencyResolver {
    var logger: Logger {
        return resolve(Logger.self, name: "logger")
    }
}
""")
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
