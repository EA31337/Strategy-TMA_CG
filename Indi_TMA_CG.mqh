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

// Structs.
// Defines struct to store indicator parameter values.
struct Indi_TMA_CG_Params : public IndicatorParams {
  // Constructors.
  /*
  void Indi_TMA_CG_Params(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    SetDefaults();
    SetDefaults(input_params);
    SetTf(_tf);
  }
  */
  /*
  void Indi_TMA_CG_Params(IndiParamEntry &_params[]) {
    SetDefaults();
    SetDefaults(input_params);
    SetInputParams(_params);
  };
  */
  // Defaults.
  void SetDefaults() {
    max_modes = FINAL_TMA_CG_MODE_ENTRY;
    custom_indi_name = "TMA+CG_mladen_NRP";
    SetDataSourceType(IDATA_ICUSTOM);
    SetDataValueRange(IDATA_RANGE_MIXED);
    SetDataValueType(TYPE_DOUBLE);
  }
  /*
  void SetDefaults(IndiParamEntry &_out[]) {
    IndiParamEntry _defaults[10];
    _defaults[0] = false;
    _defaults[1] = false;
    _defaults[2] = Indi_TMA_CG_HalfLength;
    _defaults[3] = Indi_TMA_CG_AtrPeriod;
    _defaults[4] = Indi_TMA_CG_BandsDeviations;
    _defaults[5] = Indi_TMA_CG_MA_AppliedPrice;
    _defaults[6] = Indi_TMA_CG_MM;
    _defaults[7] = Indi_TMA_CG_Period;
    _defaults[8] = Indi_TMA_CG_SignalDuration;
    _defaults[9] = Indi_TMA_CG_Interpolate;
    SetInputParams(_defaults);
  }
  */
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
        _value = iCustom(istate.handle, Get<string>(CHART_PARAM_SYMBOL), Get<ENUM_TIMEFRAMES>(CHART_PARAM_TF), params.custom_indi_name, params.tf,
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
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, _entry.IsGt<double>(0));
      if (_entry.IsValid()) {
        idata.Add(_entry, _bar_time);
      }
    }
    return _entry;
  }
};
