//+------------------------------------------------------------------+
//|                                      Copyright 2016-2020, kenorb |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// User input params.
INPUT string __TMA_True_Indi_Params__ = "-- TMA True indicator params --";  // >>> TMA True indicator <<<
INPUT int Indi_TMA_True_Timeframe = 0;                                      // Timeframe
INPUT int Indi_TMA_True_HalfLength = 3;                                     // Half length
INPUT double Indi_TMA_True_AtrMultiplier = 0.5;                             // ATR multiplier
INPUT int Indi_TMA_True_AtrPeriod = 6;                                      // ATR period
INPUT int Indi_TMA_True_BarsToProcess = 0;                                  // Bars to process
INPUT int Indi_TMA_True_Shift = 0;                                          // Indicator Shift

// Includes.
#include <EA31337-classes/Indicator.mqh>

// Indicator line identifiers used in the indicator.
enum ENUM_TMA_TRUE_MODE {
  TMA_TRUE_MAIN = 0,   // Main line.
  TMA_TRUE_UPPER = 1,  // Upper limit.
  TMA_TRUE_LOWER = 2,  // Lower limit.
  FINAL_TMA_TRUE_MODE_ENTRY,
};

// Structs.

// Defines struct to store indicator parameter values.
struct Indi_TMA_True_Params : public IndicatorParams {
  // Indicator params.
  int atr_tf;
  int half_length;
  double atr_multiplier;
  int atr_period;
  int bars_to_process;
  // Struct constructors.
  void Indi_TMA_True_Params(int _atr_tf, int _half_length, double _atr_multiplier, int _atr_period,
                            int _bars_to_process, int _shift)
      : atr_tf(_atr_tf),
        half_length(_half_length),
        atr_multiplier(_atr_multiplier),
        atr_period(_atr_period),
        bars_to_process(_bars_to_process) {
    max_modes = FINAL_TMA_TRUE_MODE_ENTRY;
    custom_indi_name = "Indi_TMA_True";
    SetDataSourceType(IDATA_ICUSTOM);
    SetDataValueType(TYPE_DOUBLE);
  };
  void Indi_TMA_True_Params(Indi_TMA_True_Params &_params, ENUM_TIMEFRAMES _tf) {
    this = _params;
    _params.tf = _tf;
  }
  // Getters.
  int GetATRTimeframe() { return atr_tf; }
  int GetHalfLength() { return half_length; }
  double GetAtrMultiplier() { return atr_multiplier; }
  int GetAtrPeriod() { return atr_period; }
  int GetBarsToProcess() { return bars_to_process; }
  // Setters.
  void SetATRTimeframe(int _value) { atr_tf = _value; }
  void SetHalfLength(int _value) { half_length = _value; }
  void SetAtrMultiplier(double _value) { atr_multiplier = _value; }
  void SetAtrPeriod(int _value) { atr_period = _value; }
  void SetBarsToProcess(int _value) { bars_to_process = _value; }
};

// Defines struct with default user indicator values.
struct Indi_TMA_True_Params_Defaults : Indi_TMA_True_Params {
  Indi_TMA_True_Params_Defaults()
      : Indi_TMA_True_Params(::Indi_TMA_True_Timeframe, ::Indi_TMA_True_HalfLength, ::Indi_TMA_True_AtrMultiplier,
                             ::Indi_TMA_True_AtrPeriod, ::Indi_TMA_True_BarsToProcess, ::Indi_TMA_True_Shift) {}
} indi_tmat_defaults;

/**
 * Implements indicator class.
 */
class Indi_TMA_True : public Indicator {
 public:
  // Structs.
  Indi_TMA_True_Params params;

  /**
   * Class constructor.
   */
  Indi_TMA_True(Indi_TMA_True_Params &_p)
      : params(_p.atr_tf, _p.half_length, _p.atr_multiplier, _p.atr_period, _p.bars_to_process, _p.shift),
        Indicator((IndicatorParams)_p) {
    params = _p;
  }
  Indi_TMA_True(Indi_TMA_True_Params &_p, ENUM_TIMEFRAMES _tf)
      : params(_p.atr_tf, _p.half_length, _p.atr_multiplier, _p.atr_period, _p.bars_to_process, _p.shift),
        Indicator(NULL, _tf) {
    params = _p;
  }

  /**
   * Gets indicator's params.
   */
  // Indi_TMA_True_Params GetIndiParams() const { return params; }

  /**
   * Returns the indicator's value.
   *
   */
  double GetValue(ENUM_TMA_TRUE_MODE _mode, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (params.idstype) {
      case IDATA_ICUSTOM:
        _value =
            iCustom(istate.handle, GetSymbol(), GetTf(), params.custom_indi_name, params.tf, params.GetHalfLength(),
                    params.GetAtrMultiplier(), params.GetAtrPeriod(), params.GetBarsToProcess(), _mode, _shift);
        break;
      default:
        SetUserError(ERR_USER_NOT_SUPPORTED);
        _value = EMPTY_VALUE;
    }
    istate.is_changed = false;
    istate.is_ready = _LastError == ERR_NO_ERROR;
    return _value;
  }

  /**
   * Returns the indicator's struct value.
   */
  IndicatorDataEntry GetEntry(int _shift = 0) {
    long _bar_time = GetBarTime(_shift);
    unsigned int _position;
    IndicatorDataEntry _entry;
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      for (ENUM_TMA_TRUE_MODE _mode = 0; _mode < FINAL_TMA_TRUE_MODE_ENTRY; _mode++) {
        _entry.value.SetValue(params.idvtype, GetValue(_mode, _shift), _mode);
      }
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, _entry.value.GetMinDbl(params.idvtype) > 0 &&
                                                   _entry.value.GetValueDbl(params.idvtype, TMA_TRUE_LOWER) <
                                                       _entry.value.GetValueDbl(params.idvtype, TMA_TRUE_UPPER));
      if (_entry.IsValid()) {
        idata.Add(_entry, _bar_time);
      }
    }
    return _entry;
  }
};
