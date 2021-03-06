/**
 * @file
 * Implements TMA_CG strategy based on the TMA_CG indicator.
 */

// User input params.
INPUT float TMA_CG_LotSize = 0;               // Lot size
INPUT int TMA_CG_Shift = 0;                   // Shift (relative to the current bar, 0 - default)
INPUT int TMA_CG_SignalOpenMethod = 0;        // Signal open method
INPUT int TMA_CG_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT float TMA_CG_SignalOpenLevel = 0;       // Signal open level
INPUT int TMA_CG_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int TMA_CG_SignalCloseMethod = 0;       // Signal close method
INPUT float TMA_CG_SignalCloseLevel = 0;      // Signal close level
INPUT int TMA_CG_PriceStopMethod = 0;         // Price stop method
INPUT float TMA_CG_PriceStopLevel = 2;        // Price stop level
INPUT int TMA_CG_TickFilterMethod = 1;        // Tick filter method (0-255)
INPUT float TMA_CG_MaxSpread = 2.0;           // Max spread to trade (in pips)

// Includes.
#include <EA31337-classes/Strategy.mqh>

#include "Indi_TMA_CG.mqh"

// Defines struct with default user strategy values.
struct Stg_TMA_CG_Params_Defaults : StgParams {
  Stg_TMA_CG_Params_Defaults()
      : StgParams(::TMA_CG_SignalOpenMethod, ::TMA_CG_SignalOpenFilterMethod, ::TMA_CG_SignalOpenLevel,
                  ::TMA_CG_SignalOpenBoostMethod, ::TMA_CG_SignalCloseMethod, ::TMA_CG_SignalCloseLevel,
                  ::TMA_CG_PriceStopMethod, ::TMA_CG_PriceStopLevel, ::TMA_CG_TickFilterMethod, ::TMA_CG_MaxSpread,
                  ::TMA_CG_Shift) {}
} stg_tmacg_defaults;

// Defines struct to store indicator and strategy params.
struct Stg_TMA_CG_Params {
  StgParams sparams;

  // Struct constructors.
  Stg_TMA_CG_Params(StgParams &_sparams) : sparams(stg_tmacg_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_TMA_CG : public Strategy {
 public:
  Stg_TMA_CG(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_TMA_CG *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_TMA_CG_Params _indi_params(_tf);
    StgParams _stg_params(stg_tmacg_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_TMA_CG_Params>(_indi_params, _tf, indi_tmacg_m1, indi_tmacg_m5, indi_tmacg_m15, indi_tmacg_m30,
                                        indi_tmacg_h1, indi_tmacg_h4, indi_tmacg_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_tmacg_m1, stg_tmacg_m5, stg_tmacg_m15, stg_tmacg_m30, stg_tmacg_h1,
                               stg_tmacg_h4, stg_tmacg_h8);
    }
    // Initialize indicator.
    _stg_params.SetIndicator(new Indi_TMA_CG(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_TMA_CG(_stg_params, "TMA CG");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indicator *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double pip_level = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // _result = _indi[CURR].value[TMA_CG_MAIN] < _indi[CURR].value[TMA_CG_LOWER] + pip_level;
        if (_method != 0) {
          // if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR].value[TMA_CG_LOWER];
        }
        break;
      case ORDER_TYPE_SELL:
        // _result = _indi[CURR].value[TMA_CG_MAIN] > _indi[CURR].value[TMA_CG_UPPER] + pip_level;
        if (_method != 0) {
          // if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR].value[TMA_CG_UPPER];
        }
        break;
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    Indi_TMA_CG *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    // int _bar_count = (int)_level * 10;
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1:
        _result = (_direction > 0 ? _indi[CURR].value[TMA_CG_UP_BUFF] : _indi[CURR].value[TMA_CG_DN_BUFF]) +
                  _trail * _direction;
        break;
      case 2:
        _result = (_direction > 0 ? _indi[PREV].value[TMA_CG_UP_BUFF] : _indi[PREV].value[TMA_CG_DN_BUFF]) +
                  _trail * _direction;
        break;
      case 3:
        _result = (_direction > 0 ? _indi[PPREV].value[TMA_CG_UP_BUFF] : _indi[PPREV].value[TMA_CG_DN_BUFF]) +
                  _trail * _direction;
        break;
      case 4:
        _result = (_direction > 0 ? fmax(_indi[PREV].value[TMA_CG_UP_BUFF], _indi[PPREV].value[TMA_CG_UP_BUFF])
                                  : fmin(_indi[PREV].value[TMA_CG_DN_BUFF], _indi[PPREV].value[TMA_CG_DN_BUFF])) +
                  _trail * _direction;
        break;
    }
    return (float)_result;
  }
};
