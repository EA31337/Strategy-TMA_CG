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

// Indicator line identifiers used in the indicator.
enum ENUM_TMA_CG_MODE {
  TMA_CG_TM_BUFF = 0,   // Temp buffer
  TMA_CG_UP_BUFF = 1,   // Upper buffer
  TMA_CG_DN_BUFF = 2,   // Down buffer
  TMA_CG_DN_ARROW = 3,  // Down arrow
  TMA_CG_UP_ARROW = 4,  // Upper arrow
  TMA_CG_WU_BUFF = 5,   // Down arrow
  TMA_CG_WD_BUFF = 6,   // Upper arrow
  FINAL_TMA_CG_MODE_ENTRY,
};

// Defines struct to store indicator parameter values.
// Structs.
struct Indi_TMA_CG_Params : IndicatorParams {
  bool CalculateTma;
  bool ReturnBars;
  int HalfLength;
  int AtrPeriod;
  double BandsDeviations;
  ENUM_APPLIED_PRICE MaAppliedPrice;
  ENUM_MA_METHOD MaMethod;
  int MaPeriod;
  int SignalDuration;
  bool Interpolate;
  bool AlertsOn;
  bool AlertsOnCurrent;
  bool AlertsOnHighLow;
  // Struct constructor.
  void Indi_TMA_CG_Params(bool _CalculateTma = false, bool _ReturnBars = false, int _HalfLength = 61,
                          int _AtrPeriod = 20, double _BandsDeviations = 2.8,
                          ENUM_APPLIED_PRICE _MaAppliedPrice = PRICE_WEIGHTED, ENUM_MA_METHOD _MaMethod = MODE_SMA,
                          int _MaPeriod = 1, int _SignalDuration = 3, bool _Interpolate = true, bool _AlertsOn = false,
                          bool _AlertsOnCurrent = false, bool _AlertsOnHighLow = false, int _shift = 0)
      : CalculateTma(_CalculateTma),
        ReturnBars(_ReturnBars),
        HalfLength(_HalfLength),
        AtrPeriod(_AtrPeriod),
        BandsDeviations(_BandsDeviations),
        MaAppliedPrice(_MaAppliedPrice),
        MaMethod(_MaMethod),
        MaPeriod(_MaPeriod),
        SignalDuration(_SignalDuration),
        Interpolate(_Interpolate),
        AlertsOn(_AlertsOn),
        AlertsOnCurrent(_AlertsOnCurrent),
        AlertsOnHighLow(_AlertsOnHighLow) {
    itype = INDI_CUSTOM;
    max_modes = FINAL_TMA_CG_MODE_ENTRY;
    custom_indi_name = "Indi_TMA_CG";
    SetDataSourceType(IDATA_ICUSTOM);
    SetDataValueType(TYPE_DOUBLE);
    SetShift(_shift);
  };
  void Indi_TMA_CG_Params(Indi_TMA_CG_Params &_params, ENUM_TIMEFRAMES _tf) {
    this = _params;
    tf = _tf;
  }
};

/**
 * Implements indicator class.
 */
class Indi_TMA_CG : public Indicator {
 protected:
  Indi_TMA_CG_Params params;

 public:
  /**
   * Class constructor.
   */
  Indi_TMA_CG(Indi_TMA_CG_Params &_p) : Indicator((IndicatorParams)_p) { params = _p; }

  /**
   * Gets indicator's params.
   */
  // Indi_TMA_CG_Params GetIndiParams() const { return params; }

  /**
   * Returns the indicator's value.
   *
   */
  double GetValue(ENUM_TMA_CG_MODE _mode, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (params.idstype) {
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), params.custom_indi_name, params.tf,
                         params.input_params[0].integer_value, params.input_params[1].integer_value,
                         params.input_params[2].integer_value, params.input_params[3].integer_value,
                         params.input_params[4].double_value, params.input_params[5].integer_value,
                         params.input_params[6].integer_value, params.input_params[7].integer_value,
                         params.input_params[8].integer_value, params.input_params[9].integer_value, _mode, _shift);
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
    IndicatorDataEntry _entry(params.max_modes);
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      for (ENUM_TMA_CG_MODE _mode = 0; _mode < FINAL_TMA_CG_MODE_ENTRY; _mode++) {
        _entry.values[_mode] = GetValue(_mode, _shift);
      }
      //_entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, !_entry.HasValue<double>(DBL_MAX));
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, _entry.IsGt<double>(0));
      if (_entry.IsValid()) {
        idata.Add(_entry, _bar_time);
      }
    }
    return _entry;
  }
};
