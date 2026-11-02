# Third-Person Aim Circle

## 한국어

HELLDIVERS 2에서 기본 3인칭 조준 원이 없는 소총에 작고 반투명한 흰색 조준 원을 표시하는 모드입니다. 게임이 제공하는 조준 정보를 우선 사용하며, 해당 정보를 읽을 수 없으면 애니메이션 조준 목표, 화면 중앙 방향 순서로 대체합니다. 탄도나 탄약을 변경하지 않습니다.

### 지원 대상과 테스트 상태

- APW-1 Anti-Materiel Rifle
- R-40 Sightliner
- AMW-20 Apex: 지원 대상으로 구현했으나 **인게임 미검증**입니다.

**제작자가 인게임 테스트를 완료했습니다. 다만 에이펙스(AMW-20 Apex)는 아직 해당 채권을 해금하지 못해 직접 테스트하지 못했습니다. 게임 데이터에서 확인한 무기 식별자를 기반으로 구현하여 이론상 작동할 것으로 예상되지만, 실제 작동을 보장하지 않습니다.**

기본 1인칭 조준경 사용 중에는 조준 원을 숨깁니다. 함선, 투척물 사용, 헬포드의 먼 카메라 등에서는 표시하지 않도록 처리했습니다. 차량 탑승 중에는 조준할 때만 표시하도록 처리했습니다. 카메라를 바꾸는 다른 모드와의 호환성은 구성에 따라 달라질 수 있습니다. 이 조준 원은 모든 거리에서 탄착점을 보장하는 탄도 계산기가 아닙니다.

### 설치 방법

1. 게임을 완전히 종료합니다.
2. [Chef Shared Loader의 최신 릴리스](https://github.com/Th3chef/Chef-Shared-Loader/releases/latest)에서 설치용 ZIP을 받아 모드 매니저에 추가하고 활성화합니다. GitHub의 `Source code` 압축파일이 아닌 **로더 릴리스 ZIP**을 사용하세요. 로더는 이 모드에 포함되어 있지 않습니다.
3. [이 모드의 Releases](https://github.com/NeverB0re/Third-Person-Aim-Circle/releases/latest)에서 **`Third-Person Aim Circle v1.0.0.zip`**을 다운로드합니다. `Source code (zip)` / `Source code (tar.gz)`는 설치 파일이 아닙니다.
4. HD2 Arsenal, Modocracy 또는 HD2MM 등 모드 ZIP 가져오기를 지원하는 매니저에서 이 ZIP을 가져옵니다. 압축을 풀어 `Addon` 폴더만 가져오는 대신 **ZIP 자체를 추가**하고, `Third-Person Aim Circle` 항목을 활성화합니다.
5. **Chef Shared Loader를 가장 높은 우선순위**로 설정합니다. Arsenal에서 `First mod highest priority`라면 맨 위, `Last mod highest priority`라면 맨 아래에 둡니다. 다른 매니저에서는 로더가 다른 `boot` 스크립트보다 우선하도록 설정합니다.
6. 매니저에서 모드를 배포/적용합니다. Arsenal에서 기존 배포를 갱신한다면 로더 안내에 따라 **Purge → Deploy**를 실행합니다. 다른 매니저에서는 해당 매니저의 배포/적용 기능을 사용합니다.
7. 게임을 실행하고 임무에서 지원 무기를 들어 확인합니다. **F9 → Third-Person Aim Circle → Aim circle**에서 표시를 켜거나 끌 수 있습니다. 기본값은 켜짐입니다.

업데이트할 때는 매니저에서 이전 버전을 제거한 뒤 새 ZIP을 가져와 다시 배포하세요. 같은 모드의 여러 버전을 동시에 활성화하지 마세요.

### 제거 및 문제 해결

- **제거:** 게임 종료 → 매니저에서 이 모드 비활성화 또는 제거 → 다시 배포/적용. 다른 애드온도 사용한다면 Chef Shared Loader는 유지하세요.
- **조준 원이 안 보일 때:** 로더 활성화와 최상위 우선순위, 배포 상태, F9의 `Aim circle` 설정, 지원 무기 사용 여부를 확인하세요. 함선이나 기본 1인칭 조준경에서는 숨겨지는 것이 정상입니다.
- **다른 로더:** Chef 애드온 API가 필요합니다. 다른 로더 단독으로는 작동을 보장하지 않습니다.
- **업데이트 이후 문제:** 게임의 내부 무기 식별자나 API가 바뀌면 표시되지 않거나 대체 조준 정보를 사용할 수 있습니다. 게임 버전, 무기, 사용 중인 로더 버전과 함께 [이슈](https://github.com/NeverB0re/Third-Person-Aim-Circle/issues)를 남겨 주세요.

### 소스 및 개발 검증

`aim_circle.lua`가 모드 소스입니다. 패치 아카이브 작성 코드를 저장소에 포함하므로 다른 로컬 프로젝트 없이 빌드할 수 있습니다.

```text
python -m pip install -r requirements-dev.txt
python test_aim_circle.py
python build_aim_circle.py
```

빌드 결과는 `dist/Third-Person Aim Circle v1.0.0.zip`입니다. 같은 버전의 출력 폴더가 이미 있으면 빌드는 덮어쓰지 않고 중단합니다. 새 체크아웃 또는 기존 결과를 별도로 보관한 상태에서 빌드하세요. Python 테스트는 모의 로더에서 실행되며 인게임 검증을 대신하지 않습니다. 배포된 v1.0.0 ZIP은 제작자가 테스트한 원본 파일입니다.

---

## English

A HELLDIVERS 2 mod that draws a small, translucent white aim circle for rifles without a default third-person aim circle. It uses the game's aim data first, then falls back to the animation aim target and finally the center-view direction when that data is unavailable. It does not change ballistics or ammunition.

### Supported weapons and testing

- APW-1 Anti-Materiel Rifle
- R-40 Sightliner
- AMW-20 Apex: implemented as a supported weapon, but **not tested in-game**.

**The author has completed in-game testing. However, the AMW-20 Apex has not been tested because the author has not unlocked its Warbond yet. Its support is based on a weapon identifier found in the game data, so it is expected to work in theory, but actual functionality is not guaranteed.**

The circle is hidden while using the normal first-person scope. The mod also suppresses it on the ship, while using throwables, and in distant hellpod camera views. In vehicles, it is intended to appear only while aiming. Compatibility with camera-changing mods depends on the setup. This circle is not a ballistic calculator guaranteeing the impact point at every range.

### Installation

1. Close the game completely.
2. Download the installable ZIP from the [latest Chef Shared Loader release](https://github.com/Th3chef/Chef-Shared-Loader/releases/latest), import it into your mod manager, and enable it. Use the **loader release ZIP**, not GitHub's `Source code` archive. The loader is not bundled with this mod.
3. Download **`Third-Person Aim Circle v1.0.0.zip`** from [this mod's Releases](https://github.com/NeverB0re/Third-Person-Aim-Circle/releases/latest). `Source code (zip)` and `Source code (tar.gz)` are not installable mod packages.
4. Import the **ZIP itself** into a manager supporting mod ZIP imports, such as HD2 Arsenal, Modocracy, or HD2MM, and enable `Third-Person Aim Circle`. Do not import only the extracted `Addon` folder.
5. Give **Chef Shared Loader the highest priority**. In Arsenal, put it at the top with `First mod highest priority`, or at the bottom with `Last mod highest priority`. In other managers, ensure the loader takes precedence over other `boot` scripts.
6. Deploy/apply the mods. When refreshing an existing Arsenal deployment, follow the loader instructions and use **Purge → Deploy**. In other managers, use their corresponding deployment/apply action.
7. Launch the game and equip a supported weapon in a mission. Toggle the circle under **F9 → Third-Person Aim Circle → Aim circle**. It is enabled by default.

To update, remove the previous version in your manager before importing the new ZIP and deploying again. Do not enable multiple versions at once.

### Uninstallation and troubleshooting

- **Uninstall:** close the game, disable/remove this mod in your manager, and deploy/apply again. Keep Chef Shared Loader if other addons still need it.
- **No circle:** check that the loader is enabled at the highest priority, the mods are deployed, `Aim circle` is enabled in F9, and you are holding a supported weapon. Hiding on the ship or in the normal first-person scope is expected.
- **Other loaders:** the Chef addon API is required. Standalone compatibility with other loaders is not guaranteed.
- **After game updates:** changed internal weapon identifiers or APIs may prevent display or cause fallback aim data to be used. Include your game version, weapon, and loader version when [reporting an issue](https://github.com/NeverB0re/Third-Person-Aim-Circle/issues).

### Source and development checks

The mod source is `aim_circle.lua`. The archive writer is included, so building does not require another local project.

```text
python -m pip install -r requirements-dev.txt
python test_aim_circle.py
python build_aim_circle.py
```

The output is `dist/Third-Person Aim Circle v1.0.0.zip`. The builder refuses to overwrite an existing output directory for the same version; use a fresh checkout or move your existing output aside first. Python tests use a simulated loader and do not replace in-game testing. The published v1.0.0 ZIP is the original file tested by the author.

### Credits

- [Chef Shared Loader](https://github.com/Th3chef/Chef-Shared-Loader) by Th3chef: required runtime, distributed separately.
- [Boot Mod Loader](https://github.com/pat-pat-patrick/boot-mod-loader) by patpatpatrick: MIT-licensed archive writer; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
- [NarrowHUD](https://github.com/luka189/NarrowHUD) by luka189: reference for identifying the local player's network avatar. No NarrowHUD code is bundled.

HELLDIVERS 2 and its weapon names belong to their respective owners. This is an unofficial fan mod.
