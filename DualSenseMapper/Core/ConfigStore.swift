import Foundation

final class ConfigStore {
    private let defaults: UserDefaults
    private let key = "DualSenseMapper.AppConfig.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppConfig {
        guard let data = defaults.data(forKey: key) else {
            return .default()
        }

        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            return .default()
        }
    }

    func save(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            defaults.set(data, forKey: key)
        } catch {
            // v1: ignore failures
        }
    }

    func resetToDefault() -> AppConfig {
        let cfg = AppConfig.default()
        save(cfg)
        return cfg
    }
}
